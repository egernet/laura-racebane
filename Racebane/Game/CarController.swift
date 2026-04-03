import SceneKit

/// Styrer en bils bevægelse langs banen
class CarController {
    let carNode: CarNode
    let trackPath: TrackPath
    let lane: Int
    let laneWidth: Float
    let laneCount: Int
    let flyOff: FlyOffController

    /// Progress langs banen (0.0 til 1.0 = en omgang)
    var progress: Float = 0.0

    /// Aktuel hastighed i meter/sekund
    var speed: Float = 0.0

    /// Er gas-pedalen trykket?
    var isThrottlePressed: Bool = false

    /// Hvor meget greb mister bilen pga. vedvarende gas i svinget (0.0 til 1.0)
    private(set) var throttleGripPenalty: Float = 0.0

    /// Antal gennemførte omgange
    var lapCount: Int = 0

    // Fysik-konstanter
    let maxSpeed: Float = 24.0
    let acceleration: Float = 6.0
    let drag: Float = 3.0
    let rollingFriction: Float = 0.5
    let throttleGripBuildRate: Float = 4.0
    let throttleGripReleaseRate: Float = 6.0

    /// Aktuel kurvaturradius (til HUD)
    var currentCurvatureRadius: Float = .infinity

    init(carNode: CarNode, trackPath: TrackPath, lane: Int = 0, laneWidth: Float = 0.4, laneCount: Int = 2) {
        self.carNode = carNode
        self.trackPath = trackPath
        self.lane = lane
        self.laneWidth = laneWidth
        self.laneCount = laneCount
        self.flyOff = FlyOffController()

        updateCarTransform()
    }

    /// Opdater bilens position og hastighed
    func update(deltaTime dt: Float) {
        let clampedDt = min(dt, 1.0 / 30.0)

        // Hvis bilen er ude af spil, opdater kun flyOff
        if flyOff.isDisabled {
            flyOff.update(deltaTime: clampedDt, carNode: carNode)

            // Når straf er ovre, nulstil hastighed og placer bilen på banen
            if !flyOff.isDisabled {
                speed = 0
                throttleGripPenalty = 0
                updateCarTransform()
            }
            return
        }

        updateThrottleGripPenalty(deltaTime: clampedDt)

        // Acceleration eller deceleration
        if isThrottlePressed {
            speed += acceleration * clampedDt
        } else {
            speed -= drag * clampedDt
        }
        speed -= rollingFriction * clampedDt
        speed = max(0, min(speed, maxSpeed))

        // Hent nuværende banepunkt for kurvatur-tjek
        let currentPoint = trackPath.pointAt(progress: progress)
        currentCurvatureRadius = currentPoint.curvatureRadius

        // Tjek om bilen flyver af
        if flyOff.checkFlyOff(
            speed: speed,
            curvatureRadius: currentPoint.curvatureRadius,
            throttleGripPenalty: throttleGripPenalty
        ) {
            flyOff.triggerFlyOff(carNode: carNode, trackPoint: currentPoint, speed: speed)
            return
        }

        // Opdater progress langs banen
        guard trackPath.totalLength > 0 else { return }
        let progressDelta = (speed * clampedDt) / trackPath.totalLength
        progress += progressDelta

        // Tjek for ny omgang
        if progress >= 1.0 {
            progress -= 1.0
            lapCount += 1
        }

        updateCarTransform()
    }

    /// Fare-niveau for HUD (0.0 til 1.0+)
    var dangerLevel: Float {
        flyOff.dangerLevel(
            speed: speed,
            curvatureRadius: currentCurvatureRadius,
            throttleGripPenalty: throttleGripPenalty
        )
    }

    private func updateThrottleGripPenalty(deltaTime dt: Float) {
        let target: Float = isThrottlePressed ? 1.0 : 0.0
        let rate = isThrottlePressed ? throttleGripBuildRate : throttleGripReleaseRate

        if throttleGripPenalty < target {
            throttleGripPenalty = min(target, throttleGripPenalty + rate * dt)
        } else {
            throttleGripPenalty = max(target, throttleGripPenalty - rate * dt)
        }
    }

    func updateCarTransform() {
        let point = trackPath.pointAt(progress: progress)
        let laneOffset = SCNFloat(Float(lane) * laneWidth - laneWidth * Float(laneCount - 1) / 2.0)
        let position = point.position + point.right * laneOffset

        carNode.position = SCNVector3(position.x, position.y, position.z)

        let angle = atan2(point.tangent.x, point.tangent.z)
        carNode.eulerAngles.y = Float(angle) + .pi
    }
}
