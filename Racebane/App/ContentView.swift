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
            if newValue { HapticManager.shared.throttlePress() }
        }
        .onChange(of: gameState.isRacing) { isRacing in
            if isRacing {
                showGoText = true
                HapticManager.shared.go()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showGoText = false
                }
            }
        }
        .onChange(of: gameState.countdownNumber) { _ in
            HapticManager.shared.countdownTick()
        }
        .onChange(of: gameState.playerLap) { _ in
            HapticManager.shared.lapComplete()
        }
        .onChange(of: isPenalty) { penalty in
            if penalty { HapticManager.shared.flyOff() }
        }
        .onChange(of: gameState.isFinished) { finished in
            if finished { HapticManager.shared.raceFinished(won: gameState.playerWon) }
        }
    }

    @AppStorage("difficulty") private var difficulty = 1
    @AppStorage("totalLaps") private var totalLaps = 3
    @AppStorage("selectedCarId") private var selectedCarId = 0

    private func setupGame() {
        let scene = RaceScene(trackDefinition: trackDefinition)
        let cam = CameraRig()
        let state = gameState
        let engine = GameEngine(raceScene: scene, cameraRig: cam, gameState: state)

        // Spillerens bil fra settings
        let carConfig = CarConfig.allCars.first(where: { $0.id == selectedCarId }) ?? CarConfig.allCars[0]
        let player = engine.addCar(color: carConfig.color, lane: 0)

        // AI-modstander
        let aiDifficulty: Float = [0.55, 0.7, 0.85][min(difficulty, 2)]
        _ = engine.addAI(color: .systemBlue, lane: 1, difficulty: aiDifficulty)

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

        engine.startRace(laps: totalLaps)
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
