import SwiftUI
import SceneKit
import MultipeerConnectivity

/// Lobby til multiplayer - host venter på spillere
struct LobbyView: View {
    let trackDefinition: TrackDefinition
    let isAR: Bool
    @StateObject private var session = SessionManager()

    init(trackDefinition: TrackDefinition, isAR: Bool = false) {
        self.trackDefinition = trackDefinition
        self.isAR = isAR
        self._session = StateObject(wrappedValue: SessionManager())
    }
    @State private var startGame = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color(red: 0.05, green: 0.15, blue: 0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Multiplayer")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text(trackDefinition.name)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                hostSection

                Spacer()

                Button("Tilbage") {
                    session.disconnect()
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 30)
            }
            .padding(.top, 60)
        }
        .navigationBarHidden(true)
        .onAppear {
            session.startHosting(trackName: trackDefinition.name, isAR: isAR)
        }
        .fullScreenCover(isPresented: $startGame) {
            MultiplayerRaceView(
                trackDefinition: trackDefinition,
                session: session,
                isHost: true,
                isAR: isAR
            )
        }
    }

    private var hostSection: some View {
        VStack(spacing: 16) {
            Text("Venter på spillere...")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            if session.connectedPeers.isEmpty {
                ProgressView()
                    .tint(.white)
                    .padding()
            }

            ForEach(session.connectedPeers, id: \.displayName) { peer in
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.green)
                    Text(peer.displayName)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
            }

            if !session.connectedPeers.isEmpty {
                Button {
                    let update = GameMessage.LobbyUpdate(
                        players: [], trackName: trackDefinition.name,
                        totalLaps: 3, isStarting: true, isAR: isAR)
                    session.sendToAll(.lobbyUpdate(update))
                    startGame = true
                } label: {
                    Text("START RACE!")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.red))
                }
            }
        }
        .padding(.horizontal, 30)
    }
}

/// Multiplayer race: host kører fysik, client viser state fra host
struct MultiplayerRaceView: View {
    let trackDefinition: TrackDefinition
    let session: SessionManager
    let isHost: Bool
    let isAR: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        if isAR {
            if isHost {
                ARHostRaceView(trackDefinition: trackDefinition, session: session)
            } else {
                ARClientRaceView(trackDefinition: trackDefinition, session: session)
            }
        } else {
            if isHost {
                HostRaceView(trackDefinition: trackDefinition, session: session)
            } else {
                ClientRaceView(trackDefinition: trackDefinition, session: session)
            }
        }
    }
}

// MARK: - Host Race View

/// Host: kører GameEngine med 2 spillerbiler, broadcaster state
struct HostRaceView: View {
    let trackDefinition: TrackDefinition
    let session: SessionManager

    @StateObject private var gameState = GameState()
    @State private var raceScene: RaceScene?
    @State private var cameraRig: CameraRig?
    @State private var gameEngine: GameEngine?
    @State private var hostEngine: HostEngine?
    @State private var playerController: CarController?
    @State private var isThrottlePressed = false
    @State private var speed: Float = 0
    @State private var lapCount: Int = 0
    @State private var dangerLevel: Float = 0
    @State private var isPenalty: Bool = false
    @State private var penaltyProgress: Float = 0
    @State private var showGoText: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            if let scene = raceScene, let cam = cameraRig, let engine = gameEngine {
                RaceView(raceScene: scene, cameraRig: cam, gameEngine: engine)
                    .ignoresSafeArea()
            }

            if gameState.isRacing {
                HUDView(speed: speed, maxSpeed: 24.0, lapCount: lapCount,
                        totalLaps: gameState.totalLaps, raceTime: gameState.raceTime,
                        dangerLevel: dangerLevel, isPenalty: isPenalty, penaltyProgress: penaltyProgress)
            }

            if let countdown = gameState.countdownNumber {
                CountdownView(number: countdown, isRacing: false)
            } else if showGoText {
                CountdownView(number: nil, isRacing: true)
            }

            if gameState.isRacing {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ThrottleButton(isPressed: $isThrottlePressed)
                            .padding(.trailing, 40).padding(.bottom, 40)
                    }
                }
            }

            if gameState.isFinished {
                ResultView(gameState: gameState,
                           onPlayAgain: { dismiss() },
                           onBackToMenu: { session.disconnect(); dismiss() })
            }
        }
        .navigationBarHidden(true)
        .onAppear { setupHostGame() }
        .onChange(of: isThrottlePressed) { newValue in
            playerController?.isThrottlePressed = newValue
        }
        .onChange(of: gameState.isRacing) { isRacing in
            if isRacing {
                showGoText = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showGoText = false }
            }
        }
    }

    private func setupHostGame() {
        let scene = RaceScene(trackDefinition: trackDefinition)
        let cam = CameraRig()
        let engine = GameEngine(raceScene: scene, cameraRig: cam, gameState: gameState)

        // Host bil (pink, spor 0)
        let player = engine.addCar(color: .systemPink, lane: 0)

        // Remote spiller bil (grøn, spor 1) - INGEN AI!
        let remoteCar = engine.addCar(color: .systemGreen, lane: 1)
        _ = remoteCar // styres via HostEngine

        // Opsæt HostEngine
        let host = HostEngine(session: session, gameEngine: engine)
        // Tildel remote peers til bil index 1
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

        cam.setupOverhead(trackPath: scene.trackPath)

        self.raceScene = scene
        self.cameraRig = cam
        self.playerController = player
        self.gameEngine = engine
        self.hostEngine = host

        // Start race + broadcasting
        engine.startRace(laps: 3)
        host.startBroadcasting()
    }
}

// MARK: - Client Race View

/// Client: viser biler positioneret af host, sender kun gas-input
struct ClientRaceView: View {
    let trackDefinition: TrackDefinition
    let session: SessionManager

    @StateObject private var clientEngine: ClientEngine
    @State private var raceScene: RaceScene?
    @State private var cameraRig: CameraRig?
    @State private var scnView: SCNView?
    @State private var isThrottlePressed = false
    @Environment(\.dismiss) var dismiss

    init(trackDefinition: TrackDefinition, session: SessionManager) {
        self.trackDefinition = trackDefinition
        self.session = session
        _clientEngine = StateObject(wrappedValue: ClientEngine(session: session, playerId: session.myId))
    }

    var body: some View {
        ZStack {
            if let scene = raceScene, let cam = cameraRig {
                ClientSceneView(scene: scene.scene, camera: cam.cameraNode)
                    .ignoresSafeArea()
            }

            if clientEngine.phase == "racing" {
                HUDView(speed: clientEngine.playerSpeed, maxSpeed: 24.0,
                        lapCount: clientEngine.playerLap, totalLaps: 3,
                        raceTime: clientEngine.raceTime, dangerLevel: 0,
                        isPenalty: clientEngine.isPlayerDisabled, penaltyProgress: 0)
            }

            if clientEngine.phase == "countdown" {
                CountdownView(number: clientEngine.countdown, isRacing: false)
            }

            if clientEngine.phase == "racing" {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ThrottleButton(isPressed: $isThrottlePressed)
                            .padding(.trailing, 40).padding(.bottom, 40)
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
        }
        .navigationBarHidden(true)
        .onAppear { setupClientGame() }
        .onChange(of: isThrottlePressed) { newValue in
            clientEngine.sendThrottle(isPressed: newValue)
        }
    }

    private func setupClientGame() {
        let scene = RaceScene(trackDefinition: trackDefinition)
        let cam = CameraRig()

        // Opret bilnoder til visning
        let hostCar = CarNode(color: .systemPink)
        let clientCar = CarNode(color: .systemGreen)
        scene.scene.rootNode.addChildNode(hostCar)
        scene.scene.rootNode.addChildNode(clientCar)

        // Registrer bilnoder i client engine
        clientEngine.trackPath = scene.trackPath
        clientEngine.carNodes["host"] = hostCar
        // Peer display names bruges som ID for remote spillere
        for peer in session.connectedPeers {
            // Host'en er den forbundne peer (vi er client)
            clientEngine.carNodes[peer.displayName] = hostCar
        }
        clientEngine.carNodes[session.myId] = clientCar

        cam.setupOverhead(trackPath: scene.trackPath)
        scene.scene.rootNode.addChildNode(cam.cameraNode)

        self.raceScene = scene
        self.cameraRig = cam
    }
}

/// Simpel SCNView wrapper til client (ingen GameEngine delegate)
struct ClientSceneView: UIViewRepresentable {
    let scene: SCNScene
    let camera: SCNNode

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = scene
        view.pointOfView = camera
        view.backgroundColor = UIColor.black
        view.antialiasingMode = .multisampling4X
        view.isPlaying = true
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}
