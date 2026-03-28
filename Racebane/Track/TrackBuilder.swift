import SceneKit

/// Bygger SCNNode-geometri fra en TrackPath
class TrackBuilder {

    /// Byg hele banen som en SCNNode
    static func buildTrack(from path: TrackPath, definition: TrackDefinition) -> SCNNode {
        let trackNode = SCNNode()

        // Byg baneoverfladen
        let surfaceNode = buildSurface(from: path, width: definition.trackWidth)
        trackNode.addChildNode(surfaceNode)

        // Byg kantsten (curbs)
        let leftCurb = buildCurb(from: path, width: definition.trackWidth, side: .left)
        let rightCurb = buildCurb(from: path, width: definition.trackWidth, side: .right)
        trackNode.addChildNode(leftCurb)
        trackNode.addChildNode(rightCurb)

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

    private enum CurbSide {
        case left, right
    }

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

    /// Byg kantsten (rød/hvid stribet)
    private static func buildCurb(from path: TrackPath, width: Float, side: CurbSide) -> SCNNode {
        let halfWidth = SCNFloat(width) / 2.0
        let curbWidth: SCNFloat = 0.15

        var vertices: [SCNVector3] = []
        var indices: [Int32] = []
        var normals: [SCNVector3] = []
        var colors: [SCNVector3] = []

        let points = path.points

        for (i, point) in points.enumerated() {
            let sideMultiplier: SCNFloat = (side == .left) ? -1.0 : 1.0
            let edgeOffset = halfWidth * sideMultiplier
            let curbOffset = (halfWidth + curbWidth) * sideMultiplier

            let inner = point.position + point.right * edgeOffset
            let outer = point.position + point.right * curbOffset

            vertices.append(inner)
            vertices.append(outer)
            normals.append(point.normal)
            normals.append(point.normal)

            // Alternerende rød/hvid farve
            let isRed = (i / 3) % 2 == 0
            let color = isRed ? SCNVector3(0.9, 0.1, 0.1) : SCNVector3(1.0, 1.0, 1.0)
            colors.append(color)
            colors.append(color)
        }

        // Luk
        if path.isClosed, let first = points.first {
            let sideMultiplier: SCNFloat = (side == .left) ? -1.0 : 1.0
            let edgeOffset = halfWidth * sideMultiplier
            let curbOffset = (halfWidth + curbWidth) * sideMultiplier

            vertices.append(first.position + first.right * edgeOffset)
            vertices.append(first.position + first.right * curbOffset)
            normals.append(first.normal)
            normals.append(first.normal)

            let isRed = (points.count / 3) % 2 == 0
            let color = isRed ? SCNVector3(0.9, 0.1, 0.1) : SCNVector3(1.0, 1.0, 1.0)
            colors.append(color)
            colors.append(color)
        }

        let segmentCount = path.isClosed ? points.count : points.count - 1
        for i in 0..<segmentCount {
            let bl = Int32(i * 2)
            let br = Int32(i * 2 + 1)
            let tl = Int32(((i + 1) % (path.isClosed ? points.count + 1 : points.count)) * 2)
            let tr = tl + 1
            indices.append(contentsOf: [bl, br, tl])
            indices.append(contentsOf: [br, tr, tl])
        }

        _ = buildGeometry(vertices: vertices, normals: normals, indices: indices)

        // Brug vertex colors for rød/hvid stribet effekt
        let colorData = Data(bytes: colors, count: colors.count * MemoryLayout<SCNVector3>.size)
        let colorSource = SCNGeometrySource(
            data: colorData,
            semantic: .color,
            vectorCount: colors.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<SCNFloat>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SCNVector3>.size
        )

        // Genbyg geometri med farve
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
        let coloredGeometry = SCNGeometry(sources: [vertexSource, normalSource, colorSource], elements: [element])

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.roughness.contents = 0.6
        coloredGeometry.materials = [material]

        let node = SCNNode(geometry: coloredGeometry)
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
