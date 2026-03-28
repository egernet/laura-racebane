import Foundation

/// Simpel AI der styrer en bil med variabel gas-brug
class AIController {
    let carController: CarController
    private var targetSpeedRatio: Float = 0.7  // Hvor aggressiv AI'en er (0-1)
    private var randomVariation: Float = 0

    init(carController: CarController, difficulty: Float = 0.7) {
        self.carController = carController
        self.targetSpeedRatio = difficulty
    }

    /// Opdater AI-beslutninger
    func update(deltaTime dt: Float) {
        // Tilføj lidt tilfældighed hvert ~0.5 sekund
        randomVariation += dt
        if randomVariation > 0.5 {
            randomVariation = 0
            targetSpeedRatio = max(0.5, min(0.9, targetSpeedRatio + Float.random(in: -0.05...0.05)))
        }

        let curvature = carController.currentCurvatureRadius
        let speed = carController.speed
        let maxSpeed = carController.maxSpeed

        if curvature < 100 {
            // I en kurve: hold lidt margin, så AI også lærer at slippe gassen
            let safeSpeed = carController.flyOff.maxSafeSpeed(
                curvatureRadius: curvature,
                throttleGripPenalty: carController.throttleGripPenalty
            )
            let curveMargin = 0.78 + targetSpeedRatio * 0.12
            let targetSpeed = safeSpeed * curveMargin

            // Slip gas hvis for hurtig, tryk gas hvis for langsom
            carController.isThrottlePressed = speed < targetSpeed
        } else {
            // Lige stykke: kør hurtigt
            let targetSpeed = maxSpeed * targetSpeedRatio
            carController.isThrottlePressed = speed < targetSpeed
        }
    }
}
