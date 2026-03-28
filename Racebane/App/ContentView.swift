import SwiftUI

struct ContentView: View {
    var body: some View {
        MenuView()
    }
}

/// Selve race-skærmen for en valgt bane
struct RaceContentView: View {
    let trackDefinition: TrackDefinition

    @Environment(\.dismiss) var dismiss
    @StateObject private var gameState = GameState()
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
    @State private var showGoText: Bool = false

    var body: some View {
        ZStack {
            // 3D scene
            if let scene = raceScene, let cam = cameraRig, let engine = gameEngine {
                RaceView(raceScene: scene, cameraRig: cam, gameEngine: engine)
                    .ignoresSafeArea()
            }

            // HUD (kun under racing)
            if gameState.isRacing {
                HUDView(
                    speed: speed,
                    maxSpeed: 15.0,
                    lapCount: lapCount,
                    totalLaps: gameState.totalLaps,
                    raceTime: gameState.raceTime,
                    dangerLevel: dangerLevel,
                    isPenalty: isPenalty,
                    penaltyProgress: penaltyProgress
                )
            }

            // Nedtælling
            if let countdown = gameState.countdownNumber {
                CountdownView(number: countdown, isRacing: false)
            } else if showGoText {
                CountdownView(number: nil, isRacing: true)
            }

            // Gas-knap (kun under racing)
            if gameState.isRacing {
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

            // Resultatskærm
            if gameState.isFinished {
                ResultView(
                    gameState: gameState,
                    onPlayAgain: { restartRace() },
                    onBackToMenu: { dismiss() }
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupGame()
        }
        .onChange(of: isThrottlePressed) { newValue in
            playerController?.isThrottlePressed = newValue
        }
        .onChange(of: gameState.isRacing) { isRacing in
            if isRacing {
                showGoText = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showGoText = false
                }
            }
        }
    }

    private func setupGame() {
        let scene = RaceScene(trackDefinition: trackDefinition)
        let cam = CameraRig()
        let state = gameState
        let engine = GameEngine(raceScene: scene, cameraRig: cam, gameState: state)

        // Spillerens bil (pink, spor 0)
        let player = engine.addCar(color: .systemPink, lane: 0)

        // AI-modstander (blå, spor 1)
        _ = engine.addAI(color: .systemBlue, lane: 1, difficulty: 0.7)

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

        // Start nedtælling
        engine.startRace(laps: 3)
    }

    private func restartRace() {
        isThrottlePressed = false
        speed = 0
        lapCount = 0
        dangerLevel = 0
        isPenalty = false

        // Nulstil biler
        if let engine = gameEngine {
            for controller in engine.carControllers {
                controller.progress = 0
                controller.speed = 0
                controller.lapCount = 0
                controller.isThrottlePressed = false
                controller.flyOff.state = .onTrack
                controller.carNode.opacity = 1.0
                controller.carNode.eulerAngles.x = 0
                controller.carNode.eulerAngles.z = 0
            }
            engine.startRace(laps: 3)
        }
    }
}

#Preview {
    ContentView()
}
