import SceneKit

/// Hoved-gameloop der kører via SceneKit's render-delegate
class GameEngine: NSObject, SCNSceneRendererDelegate {

    let raceScene: RaceScene
    let cameraRig: CameraRig
    var carControllers: [CarController] = []

    private var lastUpdateTime: TimeInterval = 0

    /// Callback til UI for at melde ændringer
    var onUpdate: (() -> Void)?

    init(raceScene: RaceScene, cameraRig: CameraRig) {
        self.raceScene = raceScene
        self.cameraRig = cameraRig
        super.init()
    }

    /// Tilføj en bil til spillet
    func addCar(color: UIColor = .systemPink, lane: Int = 0) -> CarController {
        let carNode = CarNode(color: color)
        raceScene.scene.rootNode.addChildNode(carNode)

        let controller = CarController(
            carNode: carNode,
            trackPath: raceScene.trackPath,
            lane: lane,
            laneWidth: 0.4
        )

        carControllers.append(controller)
        return controller
    }

    // MARK: - SCNSceneRendererDelegate

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = time
            return
        }

        let dt = Float(time - lastUpdateTime)
        lastUpdateTime = time

        // Opdater alle biler
        for controller in carControllers {
            controller.update(deltaTime: dt)
        }

        // Opdater kamera (følg første bil)
        if let playerCar = carControllers.first {
            cameraRig.updateChase(target: playerCar.carNode, trackPoint: playerCar.trackPath.pointAt(progress: playerCar.progress))
        }

        // Notificér UI
        DispatchQueue.main.async { [weak self] in
            self?.onUpdate?()
        }
    }
}
