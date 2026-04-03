import SceneKit

/// Hoved-gameloop der kører via SceneKit's render-delegate
class GameEngine: NSObject, SCNSceneRendererDelegate {

    let raceScene: RaceScene
    let cameraRig: CameraRig
    let gameState: GameState
    var carControllers: [CarController] = []
    var aiControllers: [AIController] = []
    var playerCarIndex: Int = 0

    private var lastUpdateTime: TimeInterval = 0
    private var countdownTimer: Float = 0
    private var currentCountdown: Int = 3
    private var lapStartTimes: [Int: Float] = [:] // carIndex -> lap start time

    /// Callback til UI for at melde ændringer
    var onUpdate: (() -> Void)?

    init(raceScene: RaceScene, cameraRig: CameraRig, gameState: GameState) {
        self.raceScene = raceScene
        self.cameraRig = cameraRig
        self.gameState = gameState
        super.init()
    }

    /// Tilføj en spillerbil
    func addCar(color: UIColor = .systemPink, lane: Int = 0) -> CarController {
        let carNode = CarNode(color: color)
        raceScene.scene.rootNode.addChildNode(carNode)

        let controller = CarController(
            carNode: carNode,
            trackPath: raceScene.trackPath,
            lane: lane,
            laneWidth: 0.4,
            laneCount: raceScene.trackDefinition.laneCount
        )

        carControllers.append(controller)
        return controller
    }

    /// Tilføj en AI-modstander
    func addAI(color: UIColor = .systemBlue, lane: Int = 1, difficulty: Float = 0.7) -> AIController {
        let controller = addCar(color: color, lane: lane)
        let ai = AIController(carController: controller, difficulty: difficulty)
        aiControllers.append(ai)
        return ai
    }

    /// Start racet (begynder nedtælling)
    func startRace(laps: Int = 3) {
        gameState.reset(laps: laps)
        currentCountdown = 3
        countdownTimer = 0
    }

    // MARK: - SCNSceneRendererDelegate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = time
            return
        }

        let dt = Float(time - lastUpdateTime)
        lastUpdateTime = time

        switch gameState.phase {
        case .countdown:
            updateCountdown(dt: dt)
        case .racing:
            updateRacing(dt: dt)
        case .finished:
            break
        }

        DispatchQueue.main.async { [weak self] in
            self?.onUpdate?()
        }
    }

    // MARK: - Private

    private func updateCountdown(dt: Float) {
        countdownTimer += dt

        if countdownTimer >= 1.0 {
            countdownTimer = 0
            currentCountdown -= 1

            if currentCountdown <= 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.gameState.phase = .racing
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.gameState.phase = .countdown(remaining: self.currentCountdown)
                }
            }
        }
    }

    private func updateRacing(dt: Float) {
        DispatchQueue.main.async { [weak self] in
            self?.gameState.raceTime += dt
        }

        // Opdater alle biler
        for (index, controller) in carControllers.enumerated() {
            let prevLap = controller.lapCount
            controller.update(deltaTime: dt)

            // Tjek for ny omgang
            if controller.lapCount > prevLap {
                handleLapComplete(carIndex: index, controller: controller)
            }
        }

        // Opdater AI
        for ai in aiControllers {
            ai.update(deltaTime: dt)
        }
    }

    private func handleLapComplete(carIndex: Int, controller: CarController) {
        let lapTime = gameState.raceTime - (lapStartTimes[carIndex] ?? 0)
        lapStartTimes[carIndex] = gameState.raceTime

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard carIndex < self.gameState.carResults.count else { return }

            self.gameState.carResults[carIndex].lap = controller.lapCount

            if lapTime < self.gameState.carResults[carIndex].bestLap {
                self.gameState.carResults[carIndex].bestLap = lapTime
            }

            // Tjek om bilen har gennemført racet
            if controller.lapCount >= self.gameState.totalLaps &&
               !self.gameState.carResults[carIndex].finished {
                self.gameState.carResults[carIndex].finished = true
                self.gameState.carResults[carIndex].totalTime = self.gameState.raceTime
            }

            // Race slut når spilleren er i mål
            if self.gameState.carResults[self.playerCarIndex].finished {
                self.gameState.phase = .finished
            }
        }
    }
}
