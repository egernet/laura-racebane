import SceneKit

/// Styrer kameraet i scenen
class CameraRig {

    enum Mode: String, CaseIterable {
        case overhead = "Oppefra"
        case side     = "Fra siden"
    }

    let cameraNode: SCNNode
    var mode: Mode = .overhead

    // Banens centrum og størrelse (beregnet én gang)
    private var centerX: Float = 0
    private var centerZ: Float = 0
    private var spanX: Float = 0
    private var spanZ: Float = 0

    init() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera!.zNear = 0.1
        cameraNode.camera!.zFar = 200
        cameraNode.camera!.fieldOfView = 60
    }

    /// Beregn banens bounding box og sæt kamera
    func setupOverhead(trackPath: TrackPath) {
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

        centerX = (minX + maxX) / 2.0
        centerZ = (minZ + maxZ) / 2.0
        spanX = maxX - minX
        spanZ = maxZ - minZ

        applyMode(.overhead)
    }

    /// Skift kamera-mode
    func applyMode(_ newMode: Mode) {
        mode = newMode
        let maxSpan = max(spanX, spanZ)

        switch mode {
        case .overhead:
            let height = maxSpan * 1.2 + 5.0
            cameraNode.camera!.fieldOfView = 60
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            cameraNode.position = SCNVector3(SCNFloat(centerX), SCNFloat(height), SCNFloat(centerZ + 2))
            cameraNode.eulerAngles = SCNVector3(-Float.pi / 2.0 + 0.1, 0, 0)
            SCNTransaction.commit()

        case .side:
            let distance = maxSpan * 0.9 + 8.0
            let height: Float = maxSpan * 0.3 + 3.0
            cameraNode.camera!.fieldOfView = 65
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            cameraNode.position = SCNVector3(SCNFloat(centerX), SCNFloat(height), SCNFloat(centerZ + distance))
            // Kig mod banens centrum
            let pitchAngle = atan2(height, distance)
            cameraNode.eulerAngles = SCNVector3(-pitchAngle, 0, 0)
            SCNTransaction.commit()
        }
    }

    /// Skift til næste kamera-mode
    func cycleMode() {
        let allModes = Mode.allCases
        let currentIndex = allModes.firstIndex(of: mode) ?? 0
        let nextIndex = (currentIndex + 1) % allModes.count
        applyMode(allModes[nextIndex])
    }
}
