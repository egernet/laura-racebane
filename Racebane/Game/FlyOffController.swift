import SceneKit

/// Håndterer afkørsel-animation og straftimer
class FlyOffController {

    enum State {
        case onTrack
        case flyingOff
        case penalty
    }

    var state: State = .onTrack
    private var penaltyTimer: Float = 0
    private var flyOffTimer: Float = 0
    private let penaltyDuration: Float = 2.0
    private let flyOffDuration: Float = 0.5

    private var flyOffStartPos: SCNVector3 = SCNVector3Zero
    private var flyOffDirection: SCNVector3 = SCNVector3Zero
    private var flyOffProgress: Float = 0

    /// Basis-greb før kurve- og gasmodifikatorer
    let baseGrip: Float = 190.0
    let maxThrottleGripPenalty: Float = 0.12

    /// Beholdt som referencepunkt for tuning og AI
    var flyOffThreshold: Float { baseGrip }

    /// Tjek om bilen skal flyve af banen
    func checkFlyOff(speed: Float, curvatureRadius: Float, throttleGripPenalty: Float) -> Bool {
        guard state == .onTrack else { return false }
        guard curvatureRadius < 100 else { return false } // Lige stykke, ingen risiko

        return dangerLevel(
            speed: speed,
            curvatureRadius: curvatureRadius,
            throttleGripPenalty: throttleGripPenalty
        ) > 1.0
    }

    /// Start afkørsel
    func triggerFlyOff(carNode: CarNode, trackPoint: PathPoint, speed: Float) {
        state = .flyingOff
        flyOffTimer = 0
        flyOffStartPos = carNode.position

        // Beregn afkørselsretning: udad fra kurven + lidt opad
        let outward = trackPoint.curveDirection >= 0 ? trackPoint.right : trackPoint.right * -1
        let tangent = trackPoint.tangent
        flyOffDirection = SCNVector3(
            SCNFloat(Float(tangent.x) * 0.5 + Float(outward.x) * 1.0),
            SCNFloat(1.5),
            SCNFloat(Float(tangent.z) * 0.5 + Float(outward.z) * 1.0)
        )

        // Tilføj gnist-partikeleffekt
        addSparkEffect(to: carNode)
    }

    /// Opdater afkørsel/straf-state
    func update(deltaTime dt: Float, carNode: CarNode) {
        switch state {
        case .onTrack:
            break

        case .flyingOff:
            flyOffTimer += dt
            flyOffProgress = flyOffTimer / flyOffDuration

            if flyOffProgress >= 1.0 {
                // Overgang til straf
                state = .penalty
                penaltyTimer = 0
                carNode.opacity = 0.4
                // Fjern partikeleffekt
                carNode.particleSystems?.forEach { carNode.removeParticleSystem($0) }
            } else {
                // Animator bilen udad og opad, derefter ned
                let t = flyOffProgress
                let height = 2.0 * Float(4 * t * (1 - t)) // Parabolsk bue
                let lateralDist = t * 2.0

                carNode.position = SCNVector3(
                    flyOffStartPos.x + flyOffDirection.x * SCNFloat(lateralDist),
                    SCNFloat(height),
                    flyOffStartPos.z + flyOffDirection.z * SCNFloat(lateralDist)
                )

                // Spin bilen
                carNode.eulerAngles.x = Float(t) * .pi * 2
                carNode.eulerAngles.z = Float(t) * .pi
            }

        case .penalty:
            penaltyTimer += dt

            // Blink-effekt
            let blink = sin(penaltyTimer * 8) > 0
            carNode.opacity = blink ? 0.6 : 0.3

            if penaltyTimer >= penaltyDuration {
                // Straf ovre - klar til at køre igen
                state = .onTrack
                carNode.opacity = 1.0
                carNode.eulerAngles.x = 0
                carNode.eulerAngles.z = 0
            }
        }
    }

    /// Hvor langt er straffen (0.0 til 1.0)
    var penaltyProgress: Float {
        guard state == .penalty else { return 0 }
        return min(penaltyTimer / penaltyDuration, 1.0)
    }

    /// Er bilen ude af spil (flyver af eller i straf)?
    var isDisabled: Bool {
        state != .onTrack
    }

    /// Beregn "fare-niveau" for nuværende hastighed i en kurve (0.0 til 1.0+)
    func dangerLevel(speed: Float, curvatureRadius: Float, throttleGripPenalty: Float) -> Float {
        guard curvatureRadius < 100 else { return 0 }

        let grip = availableGrip(
            curvatureRadius: curvatureRadius,
            throttleGripPenalty: throttleGripPenalty
        )
        guard grip > 0 else { return 0 }

        return lateralLoad(speed: speed, curvatureRadius: curvatureRadius) / grip
    }

    func lateralLoad(speed: Float, curvatureRadius: Float) -> Float {
        guard curvatureRadius < 100 else { return 0 }
        return (speed * speed) / max(curvatureRadius, 0.1)
    }

    func availableGrip(curvatureRadius: Float, throttleGripPenalty: Float) -> Float {
        guard curvatureRadius < 100 else { return .greatestFiniteMagnitude }

        let curveGripFactor = gripFactorForCurve(curvatureRadius: curvatureRadius)
        let throttleGripFactor = 1.0 - clampedUnit(throttleGripPenalty) * maxThrottleGripPenalty
        return baseGrip * curveGripFactor * throttleGripFactor
    }

    func maxSafeSpeed(curvatureRadius: Float, throttleGripPenalty: Float) -> Float {
        guard curvatureRadius < 100 else { return .greatestFiniteMagnitude }

        let grip = availableGrip(
            curvatureRadius: curvatureRadius,
            throttleGripPenalty: throttleGripPenalty
        )
        return sqrt(max(grip, 0) * curvatureRadius)
    }

    private func addSparkEffect(to node: CarNode) {
        let sparks = SCNParticleSystem()
        sparks.birthRate = 200
        sparks.particleLifeSpan = 0.3
        sparks.particleSize = 0.02
        sparks.particleColor = .yellow
        sparks.emitterShape = SCNSphere(radius: 0.1)
        sparks.spreadingAngle = 90
        sparks.particleVelocity = 2
        sparks.particleLifeSpanVariation = 0.1
        node.addParticleSystem(sparks)
    }

    private func gripFactorForCurve(curvatureRadius: Float) -> Float {
        let clampedRadius = min(max(curvatureRadius, 2.5), 4.0)
        let t = (clampedRadius - 2.5) / (4.0 - 2.5)
        return 0.95 + t * 0.10
    }

    private func clampedUnit(_ value: Float) -> Float {
        min(max(value, 0), 1)
    }
}
