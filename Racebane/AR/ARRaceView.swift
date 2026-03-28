import SwiftUI
import ARKit
import SceneKit

/// AR Race View - placer banen på et bord via AR
struct ARRaceView: UIViewRepresentable {
    let trackDefinition: TrackDefinition
    @Binding var isTrackPlaced: Bool
    @Binding var trackScale: Float
    @Binding var gameEngine: GameEngine?
    let onSceneReady: (SCNScene, TrackPath, SCNNode) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.delegate = context.coordinator
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic

        arView.session.run(config)

        // Tap gesture for at placere banen
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        // Pinch gesture for at skalere
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)

        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSCNViewDelegate {
        let parent: ARRaceView
        weak var arView: ARSCNView?
        private var planeNodes: [UUID: SCNNode] = [:]
        private var meshNodes: [UUID: SCNNode] = [:]
        private var trackNode: SCNNode?
        private var trackAnchor: ARAnchor?

        init(_ parent: ARRaceView) {
            self.parent = parent
        }

        // Vis detekterede flader som halvgennemsigtige planer
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            parent.gameEngine?.renderer(renderer, updateAtTime: time)
        }

        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                guard !parent.isTrackPlaced else { return }

                let plane = SCNPlane(
                    width: CGFloat(planeAnchor.extent.x),
                    height: CGFloat(planeAnchor.extent.z)
                )
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.3)
                plane.materials = [material]

                let planeNode = SCNNode(geometry: plane)
                planeNode.eulerAngles.x = -.pi / 2
                planeNode.position = SCNVector3(
                    planeAnchor.center.x,
                    0,
                    planeAnchor.center.z
                )
                node.addChildNode(planeNode)
                planeNodes[anchor.identifier] = planeNode

            } else if let meshAnchor = anchor as? ARMeshAnchor {
                let occluder = buildOccluderNode(from: meshAnchor.geometry)
                node.addChildNode(occluder)
                meshNodes[anchor.identifier] = occluder
            }
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            if let planeAnchor = anchor as? ARPlaneAnchor,
               let planeNode = planeNodes[anchor.identifier],
               let plane = planeNode.geometry as? SCNPlane {
                plane.width = CGFloat(planeAnchor.extent.x)
                plane.height = CGFloat(planeAnchor.extent.z)
                planeNode.position = SCNVector3(
                    planeAnchor.center.x,
                    0,
                    planeAnchor.center.z
                )
            } else if let meshAnchor = anchor as? ARMeshAnchor,
                      let occluder = meshNodes[anchor.identifier] {
                occluder.geometry = makeOccluderGeometry(from: meshAnchor.geometry)
            }
        }

        // MARK: - Mesh Occlusion

        private func buildOccluderNode(from meshGeometry: ARMeshGeometry) -> SCNNode {
            let node = SCNNode(geometry: makeOccluderGeometry(from: meshGeometry))
            node.renderingOrder = -1
            return node
        }

        private func makeOccluderGeometry(from meshGeometry: ARMeshGeometry) -> SCNGeometry {
            let vb = meshGeometry.vertices
            let vertexSource = SCNGeometrySource(
                buffer: vb.buffer, vertexFormat: .float3,
                semantic: .vertex, vertexCount: vb.count,
                dataOffset: vb.offset, dataStride: vb.stride
            )

            let nb = meshGeometry.normals
            let normalSource = SCNGeometrySource(
                buffer: nb.buffer, vertexFormat: .float3,
                semantic: .normal, vertexCount: nb.count,
                dataOffset: nb.offset, dataStride: nb.stride
            )

            let fb = meshGeometry.faces
            let indexData = Data(bytes: fb.buffer.contents(), count: fb.buffer.length)
            let element = SCNGeometryElement(
                data: indexData, primitiveType: .triangles,
                primitiveCount: fb.count, bytesPerIndex: fb.bytesPerIndex
            )

            let geometry = SCNGeometry(sources: [vertexSource, normalSource], elements: [element])
            geometry.materials = [makeOccluderMaterial()]
            return geometry
        }

        private func makeOccluderMaterial() -> SCNMaterial {
            let m = SCNMaterial()
            m.colorBufferWriteMask = []
            m.writesToDepthBuffer = true
            m.readsFromDepthBuffer = true
            m.lightingModel = .constant
            m.isDoubleSided = true
            return m
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }

            if parent.isTrackPlaced {
                return // Banen er allerede placeret
            }

            let location = gesture.location(in: arView)

            // Raycast mod horisontale flader
            guard let query = arView.raycastQuery(from: location, allowing: .existingPlaneGeometry, alignment: .horizontal),
                  let result = arView.session.raycast(query).first else { return }

            placeTrack(at: result, in: arView)
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard parent.isTrackPlaced, let trackNode = trackNode else { return }

            if gesture.state == .changed {
                let newScale = Float(gesture.scale) * parent.trackScale
                let clamped = max(0.01, min(0.15, newScale))
                trackNode.scale = SCNVector3(clamped, clamped, clamped)
            }

            if gesture.state == .ended {
                DispatchQueue.main.async {
                    self.parent.trackScale = Float(self.trackNode?.scale.x ?? 0.05)
                }
                gesture.scale = 1.0
            }
        }

        private func placeTrack(at result: ARRaycastResult, in arView: ARSCNView) {
            // Fjern flade-indikatorer
            for (_, node) in planeNodes {
                node.removeFromParentNode()
            }
            planeNodes.removeAll()

            // Byg banen
            let trackPath = TrackPath(definition: parent.trackDefinition)
            let trackBuild = TrackBuilder.buildTrack(from: trackPath, definition: parent.trackDefinition)

            // Skaler ned til bordet (banen er ~20m, bordet er ~1m)
            let scale: Float = 0.05
            trackBuild.scale = SCNVector3(scale, scale, scale)

            // Centrer banen
            var minX: Float = .infinity, maxX: Float = -.infinity
            var minZ: Float = .infinity, maxZ: Float = -.infinity
            for p in trackPath.points {
                let x = Float(p.position.x); let z = Float(p.position.z)
                minX = min(minX, x); maxX = max(maxX, x)
                minZ = min(minZ, z); maxZ = max(maxZ, z)
            }
            let cx = (minX + maxX) / 2
            let cz = (minZ + maxZ) / 2
            trackBuild.position = SCNVector3(-cx * scale, 0, -cz * scale)

            // Wrapper node ved AR-positionen
            let wrapper = SCNNode()
            wrapper.addChildNode(trackBuild)
            wrapper.transform = SCNMatrix4(result.worldTransform)

            arView.scene.rootNode.addChildNode(wrapper)

            self.trackNode = wrapper
            DispatchQueue.main.async {
                self.parent.isTrackPlaced = true
                self.parent.trackScale = scale
                self.parent.onSceneReady(arView.scene, trackPath, trackBuild)
            }
        }
    }
}
