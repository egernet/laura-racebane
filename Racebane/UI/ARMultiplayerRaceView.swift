import SwiftUI
import ARKit
import SceneKit

// MARK: - AR Host Race View

private enum ARHostPhase { case placement, waiting, racing }

/// AR Host: kører GameEngine-fysik og broadcaster state. Banen placeres i AR.
struct ARHostRaceView: View {
    let trackDefinition: TrackDefinition
    let session: SessionManager

    @StateObject private var gameState = GameState()
    @State private var hostPhase: ARHostPhase = .placement
    @State private var isTrackPlaced = false
    @State private var trackScale: Float = 0.05
    @State private var gameEngine: GameEngine?
    @State private var hostEngine: HostEngine?
    @State private var playerController: CarController?
    @State private var isThrottlePressed = false
    @State private var speed: Float = 0
    @State private var lapCount: Int = 0
    @State private var dangerLevel: Float = 0
    @State private var isPenalty: Bool = false
    @State private var penaltyProgress: Float = 0
    @State private var showGoText = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            ARRaceView(
                trackDefinition: trackDefinition,
                isTrackPlaced: $isTrackPlaced,
                trackScale: $trackScale,
                gameEngine: $gameEngine,
                onSceneReady: { scene, trackPath, trackNode in
                    setupARHost(scene: scene, trackPath: trackPath, trackNode: trackNode)
                }
            )
            .ignoresSafeArea()

            if hostPhase == .placement {
                arPlacementOverlay
            }

            if hostPhase == .waiting {
                arWaitingOverlay
            }

            if hostPhase == .racing && gameState.isRacing {
                HUDView(speed: speed, maxSpeed: 24.0, lapCount: lapCount,
                        totalLaps: gameState.totalLaps, raceTime: gameState.raceTime,
                        dangerLevel: dangerLevel, isPenalty: isPenalty,
                        penaltyProgress: penaltyProgress)
            }

            if hostPhase == .racing {
                if let countdown = gameState.countdownNumber {
                    CountdownView(number: countdown, isRacing: false)
                } else if showGoText {
                    CountdownView(number: nil, isRacing: true)
                }
            }

            if hostPhase == .racing && gameState.isRacing {
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

            if gameState.isFinished {
                ResultView(gameState: gameState,
                           onPlayAgain: { dismiss() },
                           onBackToMenu: { session.disconnect(); dismiss() })
            }

            arCloseButton { session.disconnect(); dismiss() }
        }
        .navigationBarHidden(true)
        .onAppear {
            session.startHosting(trackName: trackDefinition.name, isAR: true)
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

    private var arWaitingOverlay: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 14) {
                Text("Venter på spillere...")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if session.connectedPeers.isEmpty {
                    ProgressView().tint(.white)
                } else {
                    ForEach(session.connectedPeers, id: \.displayName) { peer in
                        HStack {
                            Image(systemName: "person.fill").foregroundColor(.green)
                            Text(peer.displayName).foregroundColor(.white)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.15)))
                    }
                }

                if !session.connectedPeers.isEmpty {
                    Button {
                        let update = GameMessage.LobbyUpdate(
                            players: [], trackName: trackDefinition.name,
                            totalLaps: 3, isStarting: true, isAR: true)
                        session.sendToAll(.lobbyUpdate(update))
                        gameEngine?.startRace(laps: 3)
                        hostEngine?.startBroadcasting()
                        hostPhase = .racing
                    } label: {
                        Text("START RACE!")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.red))
                    }
                }
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.7)))
            .padding(.horizontal, 30)
            .padding(.bottom, 100)
        }
    }

    private func setupARHost(scene: SCNScene, trackPath: TrackPath, trackNode: SCNNode) {
        let raceScene = RaceScene(trackDefinition: trackDefinition)
        let cam = CameraRig()
        let engine = GameEngine(raceScene: raceScene, cameraRig: cam, gameState: gameState)

        // Host-bil (pink, spor 0) + remote spiller-bil (grøn, spor 1)
        let player = engine.addCar(color: .systemPink, lane: 0)
        let remoteCar = engine.addCar(color: .systemGreen, lane: 1)
        _ = remoteCar // styres via HostEngine

        engine.playerCarIndex = 0
        gameState.playerIndex = 0
        gameState.carResults = [
            CarRaceResult(id: 0, name: "Dig", color: .systemPink),
            CarRaceResult(id: 1, name: "Modstander", color: .systemGreen),
        ]

        // Flyt biler fra dummy-scene til AR-bane-noden
        for controller in engine.carControllers {
            controller.carNode.removeFromParentNode()
            trackNode.addChildNode(controller.carNode)
        }

        // Opsæt HostEngine
        let host = HostEngine(session: session, gameEngine: engine)
        for peer in session.connectedPeers {
            host.assignPeer(peer.displayName, carIndex: 1)
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

        addARLighting(to: scene)

        self.playerController = player
        self.gameEngine = engine
        self.hostEngine = host

        hostPhase = .waiting
    }
}

// MARK: - AR Client Race View

/// AR Client: viser bilpositioner fra host i AR. Sender kun gas-input.
struct ARClientRaceView: View {
    let trackDefinition: TrackDefinition
    let session: SessionManager

    @StateObject private var clientEngine: ClientEngine
    @State private var isTrackPlaced = false
    @State private var trackScale: Float = 0.05
    @State private var nullEngine: GameEngine? = nil  // Client bruger ikke GameEngine
    @Environment(\.dismiss) var dismiss

    @State private var isThrottlePressed = false

    init(trackDefinition: TrackDefinition, session: SessionManager) {
        self.trackDefinition = trackDefinition
        self.session = session
        _clientEngine = StateObject(wrappedValue: ClientEngine(session: session, playerId: session.myId))
    }

    var body: some View {
        ZStack {
            ARRaceView(
                trackDefinition: trackDefinition,
                isTrackPlaced: $isTrackPlaced,
                trackScale: $trackScale,
                gameEngine: $nullEngine,
                autoPlace: true,
                onSceneReady: { scene, trackPath, trackNode in
                    setupARClient(scene: scene, trackPath: trackPath, trackNode: trackNode)
                }
            )
            .ignoresSafeArea()

            if !isTrackPlaced {
                arPlacementOverlay
            }

            if isTrackPlaced && clientEngine.phase == "racing" {
                HUDView(speed: clientEngine.playerSpeed, maxSpeed: 24.0,
                        lapCount: clientEngine.playerLap, totalLaps: 3,
                        raceTime: clientEngine.raceTime, dangerLevel: 0,
                        isPenalty: clientEngine.isPlayerDisabled, penaltyProgress: 0)
            }

            if isTrackPlaced && clientEngine.phase == "countdown" {
                CountdownView(number: clientEngine.countdown, isRacing: false)
            }

            if isTrackPlaced && clientEngine.phase == "racing" {
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

            if clientEngine.phase == "finished" {
                VStack(spacing: 20) {
                    Text(clientEngine.winnerId == clientEngine.playerId ? "DU VANDT!" : "DU TABTE!")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundColor(clientEngine.winnerId == clientEngine.playerId ? .yellow : .red)
                    Button("Tilbage") { session.disconnect(); dismiss() }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.2)))
                }
                .padding(30)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.black.opacity(0.7)))
            }

            if !clientEngine.gameStarted {
                VStack {
                    ProgressView().tint(.white)
                    Text("Venter på host...").foregroundColor(.white)
                }
            }

            arCloseButton { session.disconnect(); dismiss() }
        }
        .navigationBarHidden(true)
        .onChange(of: isThrottlePressed) { newValue in
            clientEngine.sendThrottle(isPressed: newValue)
        }
    }

    private func setupARClient(scene: SCNScene, trackPath: TrackPath, trackNode: SCNNode) {
        // Opret biler og tilføj direkte til AR-bane-noden
        let hostCar = CarNode(color: .systemPink)
        let clientCar = CarNode(color: .systemGreen)
        trackNode.addChildNode(hostCar)
        trackNode.addChildNode(clientCar)

        // Registrer trackPath og bilnoder i ClientEngine
        clientEngine.trackPath = trackPath
        clientEngine.carNodes["host"] = hostCar
        for peer in session.connectedPeers {
            clientEngine.carNodes[peer.displayName] = hostCar
        }
        clientEngine.carNodes[session.myId] = clientCar

        addARLighting(to: scene)
    }
}

// MARK: - AR Host Entry (bruges fra menuen)

/// Wrapper der giver ARHostRaceView sin egen SessionManager
struct ARMultiplayerHostEntry: View {
    let trackDefinition: TrackDefinition
    @StateObject private var session = SessionManager()

    var body: some View {
        ARHostRaceView(trackDefinition: trackDefinition, session: session)
    }
}

// MARK: - Delte hjælpe-views og funktioner

private var arPlacementOverlay: some View {
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
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.6)))
        .padding(.bottom, 100)
    }
}

private func arCloseButton(action: @escaping () -> Void) -> some View {
    VStack {
        HStack {
            Button(action: action) {
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

private func addARLighting(to scene: SCNScene) {
    let sun = SCNNode()
    sun.light = SCNLight()
    sun.light!.type = .directional
    sun.light!.color = UIColor(white: 0.9, alpha: 1.0)
    sun.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
    scene.rootNode.addChildNode(sun)

    let ambient = SCNNode()
    ambient.light = SCNLight()
    ambient.light!.type = .ambient
    ambient.light!.color = UIColor(white: 0.5, alpha: 1.0)
    scene.rootNode.addChildNode(ambient)
}
