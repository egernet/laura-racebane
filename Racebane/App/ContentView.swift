import SwiftUI

struct ContentView: View {
    var body: some View {
        MenuView()
    }
}

/// Selve race-skærmen for en valgt bane
struct RaceContentView: View {
    let trackDefinition: TrackDefinition

    @State private var raceScene: RaceScene?
    @State private var cameraRig: CameraRig?
    @State private var gameEngine: GameEngine?
    @State private var playerController: CarController?
    @State private var isThrottlePressed = false
    @State private var speed: Float = 0
    @State private var lapCount: Int = 0
    @State private var dangerLevel: Float = 0
    @State private var isPenalty: Bool = false
    @State private var penaltyProgress: Float = 0

    var body: some View {
        ZStack {
            if let scene = raceScene, let cam = cameraRig, let engine = gameEngine {
                RaceView(raceScene: scene, cameraRig: cam, gameEngine: engine)
                    .ignoresSafeArea()
            }

            HUDView(
                speed: speed,
                maxSpeed: 15.0,
                lapCount: lapCount,
                dangerLevel: dangerLevel,
                isPenalty: isPenalty,
                penaltyProgress: penaltyProgress
            )

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ThrottleButton(isPressed: $isThrottlePressed)
                        .padding(.trailing, 40)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupGame()
        }
        .onChange(of: isThrottlePressed) { newValue in
            playerController?.isThrottlePressed = newValue
        }
    }

    private func setupGame() {
        let scene = RaceScene(trackDefinition: trackDefinition)
        let cam = CameraRig()
        let engine = GameEngine(raceScene: scene, cameraRig: cam)
        let player = engine.addCar(color: .systemPink, lane: 0)

        engine.onUpdate = { [weak player] in
            if let p = player {
                speed = p.speed
                lapCount = p.lapCount
                dangerLevel = p.dangerLevel
                isPenalty = p.flyOff.state == .penalty
                penaltyProgress = p.flyOff.penaltyProgress
            }
        }

        cam.setupOverhead(trackPath: scene.trackPath)

        self.raceScene = scene
        self.cameraRig = cam
        self.playerController = player
        self.gameEngine = engine
    }
}

#Preview {
    ContentView()
}
