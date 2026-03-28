import SceneKit

/// Bygger SCNNode-geometri fra en TrackPath
class TrackBuilder {

    /// Byg hele banen som en SCNNode
    static func buildTrack(from path: TrackPath, definition: TrackDefinition) -> SCNNode {
        let trackNode = SCNNode()

        // Byg baneoverfladen
        let surfaceNode = buildSurface(from: path, width: definition.trackWidth)
        trackNode.addChildNode(surfaceNode)

        // Byg kantsten (curbs) - kun på ydersiden af kurver
        let outsideCurb = buildOutsideCurb(from: path, width: definition.trackWidth)
        trackNode.addChildNode(outsideCurb)

        // Byg sporstriber
        for lane in 0..<definition.laneCount {
            let laneOffset = SCNFloat(lane) * SCNFloat(definition.laneWidth) - SCNFloat(definition.laneWidth) * 0.5
            let stripe = buildLaneStripe(from: path, offset: laneOffset)
            trackNode.addChildNode(stripe)
        }

        // Byg startlinje
        let startLine = buildStartLine(from: path, width: definition.trackWidth)
        trackNode.addChildNode(startLine)

        return trackNode
    }

    // MARK: - Private helpers

    /// Byg baneoverfladen som en extruded mesh
    private static func buildSurface(from path: TrackPath, width: Float) -> SCNNode {
        let halfWidth = SCNFloat(width) / 2.0

        var vertices: [SCNVector3] = []
        var indices: [Int32] = []
        var normals: [SCNVector3] = []

        let points = path.points
        guard points.count >= 2 else { return SCNNode() }

        // Generer vertices: venstre og højre kant for hvert punkt
        for point in points {
            let left = point.position - point.right * halfWidth
            let right = point.position + point.right * halfWidth
            vertices.append(left)
            vertices.append(right)
            normals.append(point.normal)
            normals.append(point.normal)
        }

        // Luk banen ved at forbinde sidste punkt til første
        if path.isClosed, let first = points.first {
            let left = first.position - first.right * halfWidth
            let right = first.position + first.right * halfWidth
            vertices.append(left)
            vertices.append(right)
            normals.append(first.normal)
            normals.append(first.normal)
        }

        // Generer triangler
        let segmentCount = path.isClosed ? points.count : points.count - 1
        for i in 0..<segmentCount {
            let bl = Int32(i * 2)
            let br = Int32(i * 2 + 1)
            let tl = Int32(((i + 1) % (path.isClosed ? points.count + 1 : points.count)) * 2)
            let tr = tl + 1

            // Triangel 1
            indices.append(contentsOf: [bl, br, tl])
            // Triangel 2
            indices.append(contentsOf: [br, tr, tl])
        }

        let geometry = buildGeometry(vertices: vertices, normals: normals, indices: indices)

        // Mørk grå asfalt
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1.0)
        material.roughness.contents = 0.8
        geometry.materials = [material]

        let node = SCNNode(geometry: geometry)
        node.position.y = 0.01 // Lidt over ground plane
        return node
    }

    /// Byg kantsten (rød/hvid) KUN på ydersiden af kurver.
    /// Venstre-kurve → rabat på højre side (ydersiden).
    /// Højre-kurve → rabat på venstre side.
    /// Lige stykker → ingen rabat.
    private static func buildOutsideCurb(from path: TrackPath, width: Float) -> SCNNode {
        let halfWidth = SCNFloat(width) / 2.0
        let curbWidth: SCNFloat = 0.15

        var vertices: [SCNVector3] = []
        var indices: [Int32] = []
        var normals: [SCNVector3] = []
        var colors: [SCNVector3] = []

        let points = path.points
        var stripeCounter = 0

        for (i, point) in points.enumerated() {
            // Tjek kurvatur: positiv radius og ikke uendelig = kurve
            let isCurve = point.curvatureRadius < 100
            guard isCurve else {
                // Lige stykke: tilføj dummy vertices (usynlige)
                vertices.append(point.position)
                vertices.append(point.position)
                normals.append(point.normal)
                normals.append(point.normal)
                colors.append(SCNVector3Zero)
                colors.append(SCNVector3Zero)
                stripeCounter = 0
                continue
            }

            // Bestem yderside: for venstre-kurve (positiv vinkel) er ydersiden højre (+right)
            // Vi kan detektere dette fra kurvaturens retning. I vores TrackPath bruger vi
            // konventionen at positive kurver drejer til venstre, så ydersiden er +right.
            // For at bestemme retning, se på ændring i heading mellem to punkter.
            let outsideMultiplier: SCNFloat
            if i > 0 {
                let prevTangent = points[i-1].tangent
                let cross = prevTangent.x * point.tangent.z - prevTangent.z * point.tangent.x
                outsideMultiplier = Float(cross) >= 0 ? 1.0 : -1.0  // Venstre-sving → højre er ude
            } else {
                outsideMultiplier = 1.0
            }

            let edgeOffset = halfWidth * outsideMultiplier
            let curbOffset = (halfWidth + curbWidth) * outsideMultiplier

            let inner = point.position + point.right * edgeOffset
            let outer = point.position + point.right * curbOffset

            vertices.append(inner)
            vertices.append(outer)
            normals.append(point.normal)
            normals.append(point.normal)

            let isRed = (stripeCounter / 3) % 2 == 0
            let color = isRed ? SCNVector3(0.9, 0.1, 0.1) : SCNVector3(1.0, 1.0, 1.0)
            colors.append(color)
            colors.append(color)
            stripeCounter += 1
        }

        // Generer kun triangler for kurve-segmenter (spring over lige stykker)
        let segmentCount = path.isClosed ? points.count : points.count - 1
        for i in 0..<segmentCount {
            let nextI = (i + 1) % points.count
            let isCurve = points[i].curvatureRadius < 100
            let nextIsCurve = points[nextI].curvatureRadius < 100
            guard isCurve && nextIsCurve else { continue }

            let bl = Int32(i * 2)
            let br = Int32(i * 2 + 1)
            let tl = Int32(nextI * 2)
            let tr = tl + 1
            indices.append(contentsOf: [bl, br, tl])
            indices.append(contentsOf: [br, tr, tl])
        }

        guard !indices.isEmpty else { return SCNNode() }

        // Byg geometri med vertex colors
        let vertexData = Data(bytes: vertices, count: vertices.count * MemoryLayout<SCNVector3>.size)
        let vertexSource = SCNGeometrySource(
            data: vertexData, semantic: .vertex, vectorCount: vertices.count,
            usesFloatComponents: true, componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<SCNFloat>.size,
            dataOffset: 0, dataStride: MemoryLayout<SCNVector3>.size
        )
        let normalData = Data(bytes: normals, count: normals.count * MemoryLayout<SCNVector3>.size)
        let normalSource = SCNGeometrySource(
            data: normalData, semantic: .normal, vectorCount: normals.count,
            usesFloatComponents: true, componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<SCNFloat>.size,
            dataOffset: 0, dataStride: MemoryLayout<SCNVector3>.size
        )
        let colorData = Data(bytes: colors, count: colors.count * MemoryLayout<SCNVector3>.size)
        let colorSource = SCNGeometrySource(
            data: colorData, semantic: .color, vectorCount: colors.count,
            usesFloatComponents: true, componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<SCNFloat>.size,
            dataOffset: 0, dataStride: MemoryLayout<SCNVector3>.size
        )
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)
        let element = SCNGeometryElement(
            data: indexData, primitiveType: .triangles,
            primitiveCount: indices.count / 3,
            bytesPerIndex: MemoryLayout<Int32>.size
        )

        let geometry = SCNGeometry(sources: [vertexSource, normalSource, colorSource], elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.roughness.contents = 0.6
        geometry.materials = [material]

        let node = SCNNode(geometry: geometry)
        node.position.y = 0.02
        return node
    }

    /// Byg en sporstreg (hvid stiplet linje)
    private static func buildLaneStripe(from path: TrackPath, offset: SCNFloat) -> SCNNode {
        let stripeWidth: SCNFloat = 0.03
        var vertices: [SCNVector3] = []
        var indices: [Int32] = []
        var normals: [SCNVector3] = []

        let points = path.points

        for point in points {
            let center = point.position + point.right * offset
            let left = center - point.right * stripeWidth
            let right = center + point.right * stripeWidth
            vertices.append(left)
            vertices.append(right)
            normals.append(point.normal)
            normals.append(point.normal)
        }

        if path.isClosed, let first = points.first {
            let center = first.position + first.right * offset
            vertices.append(center - first.right * stripeWidth)
            vertices.append(center + first.right * stripeWidth)
            normals.append(first.normal)
            normals.append(first.normal)
        }

        let segmentCount = path.isClosed ? points.count : points.count - 1
        for i in 0..<segmentCount {
            // Stiplet: vis kun hvert andet segment
            if (i / 5) % 2 == 0 {
                let bl = Int32(i * 2)
                let br = Int32(i * 2 + 1)
                let tl = Int32(((i + 1) % (path.isClosed ? points.count + 1 : points.count)) * 2)
                let tr = tl + 1
                indices.append(contentsOf: [bl, br, tl])
                indices.append(contentsOf: [br, tr, tl])
            }
        }

        let geometry = buildGeometry(vertices: vertices, normals: normals, indices: indices)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.roughness.contents = 0.5
        geometry.materials = [material]

        let node = SCNNode(geometry: geometry)
        node.position.y = 0.015
        return node
    }

    /// Byg startlinje
    private static func buildStartLine(from path: TrackPath, width: Float) -> SCNNode {
        guard let first = path.points.first else { return SCNNode() }
        let halfWidth = SCNFloat(width) / 2.0

        let box = SCNBox(width: CGFloat(halfWidth * 2), height: 0.01, length: 0.15, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        box.materials = [material]

        let node = SCNNode(geometry: box)
        node.position = first.position
        node.position.y = 0.025

        // Roter til at pege på tværs af banen
        let angle = atan2(first.tangent.z, first.tangent.x)
        node.eulerAngles.y = -Float(angle)

        return node
    }

    /// Hjælpefunktion til at bygge SCNGeometry
    private static func buildGeometry(vertices: [SCNVector3], normals: [SCNVector3], indices: [Int32]) -> SCNGeometry {
        let vertexData = Data(bytes: vertices, count: vertices.count * MemoryLayout<SCNVector3>.size)
        let vertexSource = SCNGeometrySource(
            data: vertexData,
            semantic: .vertex,
            vectorCount: vertices.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<SCNFloat>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SCNVector3>.size
        )

        let normalData = Data(bytes: normals, count: normals.count * MemoryLayout<SCNVector3>.size)
        let normalSource = SCNGeometrySource(
            data: normalData,
            semantic: .normal,
            vectorCount: normals.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<SCNFloat>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SCNVector3>.size
        )

        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)
        let element = SCNGeometryElement(
            data: indexData,
            primitiveType: .triangles,
            primitiveCount: indices.count / 3,
            bytesPerIndex: MemoryLayout<Int32>.size
        )

        return SCNGeometry(sources: [vertexSource, normalSource], elements: [element])
    }
}
