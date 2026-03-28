import SceneKit

/// Styrer en bils bevægelse langs banen
class CarController {
    let carNode: CarNode
    let trackPath: TrackPath
    let lane: Int
    let laneWidth: Float

    /// Progress langs banen (0.0 til 1.0 = en omgang)
    var progress: Float = 0.0

    /// Aktuel hastighed i meter/sekund
    var speed: Float = 0.0

    /// Er gas-pedalen trykket?
    var isThrottlePressed: Bool = false

    /// Antal gennemførte omgange
    var lapCount: Int = 0

    // Fysik-konstanter
    let maxSpeed: Float = 15.0       // Max hastighed m/s
    let acceleration: Float = 6.0     // Acceleration m/s²
    let drag: Float = 3.0             // Deceleration når gas slippes m/s²
    let rollingFriction: Float = 0.5  // Konstant friktion m/s²

    init(carNode: CarNode, trackPath: TrackPath, lane: Int = 0, laneWidth: Float = 0.4) {
        self.carNode = carNode
        self.trackPath = trackPath
        self.lane = lane
        self.laneWidth = laneWidth

        // Placer bil på startposition
        updateCarTransform()
    }

    /// Opdater bilens position og hastighed
    func update(deltaTime dt: Float) {
        // Begræns dt for at undgå store spring
        let clampedDt = min(dt, 1.0 / 30.0)

        // Acceleration eller deceleration
        if isThrottlePressed {
            speed += acceleration * clampedDt
        } else {
            speed -= drag * clampedDt
        }

        // Rolling friction
        speed -= rollingFriction * clampedDt

        // Clamp hastighed
        speed = max(0, min(speed, maxSpeed))

        // Opdater progress langs banen
        guard trackPath.totalLength > 0 else { return }
        let progressDelta = (speed * clampedDt) / trackPath.totalLength
        let oldProgress = progress
        progress += progressDelta

        // Tjek for ny omgang
        if progress >= 1.0 {
            progress -= 1.0
            lapCount += 1
        }

        // Opdater bilens 3D-position
        updateCarTransform()
    }

    /// Sæt bilens position og rotation ud fra progress
    private func updateCarTransform() {
        let point = trackPath.pointAt(progress: progress)

        // Beregn lane-offset
        let laneOffset = SCNFloat(Float(lane) * laneWidth - laneWidth * 0.5)
        let position = point.position + point.right * laneOffset

        carNode.position = SCNVector3(position.x, 0, position.z)

        // Roter bilen til at pege langs banen
        let angle = atan2(point.tangent.x, point.tangent.z)
        carNode.eulerAngles.y = Float(angle) + .pi
    }
}
