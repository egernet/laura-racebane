import SceneKit

/// Styrer kameraet i scenen
class CameraRig {

    enum Mode {
        case overhead    // Fuld oversigt over banen
        case chase       // Følger en bil bagfra
    }

    let cameraNode: SCNNode
    var mode: Mode = .overhead

    // Chase-kamera indstillinger
    private let chaseHeight: Float = 3.0
    private let chaseDistance: Float = 5.0
    private let chaseSmoothness: Float = 0.08

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

        let height = maxSpan * 1.2 + 5.0
        cameraNode.position = SCNVector3(SCNFloat(centerX), SCNFloat(height), SCNFloat(centerZ + 2))
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 2.0 + 0.1, 0, 0)
    }

    /// Skift til chase-kamera
    func setupChase() {
        mode = .chase
        cameraNode.camera!.fieldOfView = 70
    }

    /// Opdater chase-kamera (kaldes hvert frame)
    func updateChase(target: SCNNode, trackPoint: PathPoint) {
        guard mode == .chase else { return }

        // Beregn ønsket kameraposition: bag bilen og opad
        let backDir = SCNVector3(
            SCNFloat(-trackPoint.tangent.x),
            0,
            SCNFloat(-trackPoint.tangent.z)
        )
        let targetPos = SCNVector3(
            target.position.x + backDir.x * SCNFloat(chaseDistance),
            SCNFloat(chaseHeight),
            target.position.z + backDir.z * SCNFloat(chaseDistance)
        )

        // Blød interpolation (lerp) for at undgå ryk
        let t = SCNFloat(chaseSmoothness)
        cameraNode.position = SCNVector3(
            cameraNode.position.x + (targetPos.x - cameraNode.position.x) * t,
            cameraNode.position.y + (targetPos.y - cameraNode.position.y) * t,
            cameraNode.position.z + (targetPos.z - cameraNode.position.z) * t
        )

        // Kig mod bilen
        let lookTarget = SCNVector3(
            target.position.x,
            SCNFloat(0.5),
            target.position.z
        )
        let dx = lookTarget.x - cameraNode.position.x
        let dy = lookTarget.y - cameraNode.position.y
        let dz = lookTarget.z - cameraNode.position.z
        let horizontalDist = sqrt(dx * dx + dz * dz)

        cameraNode.eulerAngles.x = Float(atan2(dy, horizontalDist))
        cameraNode.eulerAngles.y = Float(atan2(dx, dz))
        cameraNode.eulerAngles.z = 0
    }
}
