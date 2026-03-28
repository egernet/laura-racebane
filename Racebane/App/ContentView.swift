import SwiftUI

struct ContentView: View {
    private let raceScene = RaceScene()
    private let cameraRig = CameraRig()
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
            if let engine = gameEngine {
                RaceView(raceScene: raceScene, cameraRig: cameraRig, gameEngine: engine)
                    .ignoresSafeArea()
            }

            // HUD overlay
            HUDView(
                speed: speed,
                maxSpeed: 15.0,
                lapCount: lapCount,
                dangerLevel: dangerLevel,
                isPenalty: isPenalty,
                penaltyProgress: penaltyProgress
            )

            // Gas-knap
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
        .onAppear {
            setupGame()
        }
        .onChange(of: isThrottlePressed) { newValue in
            playerController?.isThrottlePressed = newValue
        }
    }

    private func setupGame() {
        let engine = GameEngine(raceScene: raceScene, cameraRig: cameraRig)
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

        cameraRig.setupOverhead(trackPath: raceScene.trackPath)

        self.playerController = player
        self.gameEngine = engine
    }
}

#Preview {
    ContentView()
}
