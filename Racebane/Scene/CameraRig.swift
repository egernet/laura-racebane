import SceneKit

/// Styrer kameraet i scenen
class CameraRig {

    enum Mode {
        case overhead    // Fuld oversigt over banen
        case chase       // Følger en bil (bruges i fase 2)
    }

    let cameraNode: SCNNode
    var mode: Mode = .overhead

    init() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera!.zNear = 0.1
        cameraNode.camera!.zFar = 200
        cameraNode.camera!.fieldOfView = 60
    }

    /// Sæt kameraet op til overhead-visning af banen
    func setupOverhead(trackPath: TrackPath) {
        mode = .overhead

        // Find banens centrum og størrelse
        guard !trackPath.points.isEmpty else { return }

        var minX: Float = .infinity
        var maxX: Float = -.infinity
        var minZ: Float = .infinity
        var maxZ: Float = -.infinity

        for point in trackPath.points {
            let x = Float(point.position.x)
            let z = Float(point.position.z)
            minX = min(minX, x)
            maxX = max(maxX, x)
            minZ = min(minZ, z)
            maxZ = max(maxZ, z)
        }

        let centerX = (minX + maxX) / 2.0
        let centerZ = (minZ + maxZ) / 2.0
        let spanX = maxX - minX
        let spanZ = maxZ - minZ
        let maxSpan = max(spanX, spanZ)

        // Placer kameraet over centrum
        let height = maxSpan * 1.2 + 5.0
        cameraNode.position = SCNVector3(SCNFloat(centerX), SCNFloat(height), SCNFloat(centerZ + 2))
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 2.0 + 0.1, 0, 0)
    }
}
