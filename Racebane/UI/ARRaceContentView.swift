import SwiftUI
import ARKit
import SceneKit

/// AR Race - placer banen på bordet og race i augmented reality
struct ARRaceContentView: View {
    let trackDefinition: TrackDefinition

    @Environment(\.dismiss) var dismiss
    @StateObject private var gameState = GameState()
    @State private var isTrackPlaced = false
    @State private var trackScale: Float = 0.05
    @State private var gameEngine: GameEngine?
    @State private var playerController: CarController?
    @State private var isThrottlePressed = false
    @State private var speed: Float = 0
    @State private var lapCount: Int = 0
    @State private var dangerLevel: Float = 0
    @State private var isPenalty: Bool = false
    @State private var penaltyProgress: Float = 0
    @State private var showGoText = false

    @AppStorage("difficulty") private var difficulty = 1
    @AppStorage("totalLaps") private var totalLaps = 3
    @AppStorage("selectedCarId") private var selectedCarId = 0

    var body: some View {
        ZStack {
            // AR View
            ARRaceView(
                trackDefinition: trackDefinition,
                isTrackPlaced: $isTrackPlaced,
                trackScale: $trackScale,
                onSceneReady: { scene, trackPath in
                    setupARGame(scene: scene, trackPath: trackPath)
                }
            )
            .ignoresSafeArea()

            // Instruktion før placering
            if !isTrackPlaced {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        Text("Peg kameraet mod et bord")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Tryk for at placere banen")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        Text("Knib for at ændre størrelse")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.6)))
                    .padding(.bottom, 100)
                }
            }

            // HUD efter placering
            if isTrackPlaced && gameState.isRacing {
                HUDView(speed: speed, maxSpeed: 24.0, lapCount: lapCount,
                        totalLaps: gameState.totalLaps, raceTime: gameState.raceTime,
                        dangerLevel: dangerLevel, isPenalty: isPenalty, penaltyProgress: penaltyProgress)
            }

            // Nedtælling
            if isTrackPlaced {
                if let countdown = gameState.countdownNumber {
                    CountdownView(number: countdown, isRacing: false)
                } else if showGoText {
                    CountdownView(number: nil, isRacing: true)
                }
            }

            // Gas-knap
            if isTrackPlaced && gameState.isRacing {
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

            // Resultat
            if gameState.isFinished {
                ResultView(gameState: gameState,
                           onPlayAgain: { dismiss() },
                           onBackToMenu: { dismiss() })
            }

            // Luk-knap
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.leading, 20)
                    .padding(.top, 50)
                    Spacer()
                }
                Spacer()
            }
        }
        .onChange(of: isThrottlePressed) { newValue in
            playerController?.isThrottlePressed = newValue
            if newValue { HapticManager.shared.throttlePress() }
        }
        .onChange(of: gameState.isRacing) { isRacing in
            if isRacing {
                showGoText = true
                HapticManager.shared.go()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showGoText = false }
            }
        }
        .onChange(of: gameState.countdownNumber) { _ in HapticManager.shared.countdownTick() }
        .onChange(of: isPenalty) { p in if p { HapticManager.shared.flyOff() } }
        .onChange(of: gameState.isFinished) { f in
            if f { HapticManager.shared.raceFinished(won: gameState.playerWon) }
        }
    }

    private func setupARGame(scene: SCNScene, trackPath: TrackPath) {
        // Opret en dummy RaceScene wrapper for GameEngine
        let raceScene = RaceScene(trackDefinition: trackDefinition)
        let cam = CameraRig() // Bruges ikke i AR, men GameEngine kræver det

        let engine = GameEngine(raceScene: raceScene, cameraRig: cam, gameState: gameState)

        let carConfig = CarConfig.allCars.first(where: { $0.id == selectedCarId }) ?? CarConfig.allCars[0]
        let player = engine.addCar(color: carConfig.color, lane: 0)

        let aiDifficulty: Float = [0.55, 0.7, 0.85][min(difficulty, 2)]
        _ = engine.addAI(color: .systemBlue, lane: 1, difficulty: aiDifficulty)

        // Skaler bilerne ned til AR-størrelse og tilføj til AR-scenen
        for controller in engine.carControllers {
            controller.carNode.scale = SCNVector3(trackScale, trackScale, trackScale)
        }

        engine.onUpdate = { [weak player] in
            if let p = player {
                speed = p.speed
                lapCount = p.lapCount
                dangerLevel = p.dangerLevel
                isPenalty = p.flyOff.state == .penalty
                penaltyProgress = p.flyOff.penaltyProgress
            }
        }

        self.playerController = player
        self.gameEngine = engine

        engine.startRace(laps: totalLaps)
    }
}
