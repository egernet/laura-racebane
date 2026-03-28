import Foundation
import MultipeerConnectivity

/// Host-side spilmotor: kører fysik for alle biler, broadcaster state
class HostEngine {
    let session: SessionManager
    let gameEngine: GameEngine
    private var peerCarIndex: [String: Int] = [:]
    private var broadcastTimer: Timer?

    init(session: SessionManager, gameEngine: GameEngine) {
        self.session = session
        self.gameEngine = gameEngine

        session.onMessageReceived = { [weak self] message, peer in
            self?.handleMessage(message, from: peer)
        }

        // Tildel automatisk nye peers til næste ledige bil-index (> 0)
        session.onPeerConnected = { [weak self] peer in
            guard let self = self else { return }
            if self.peerCarIndex[peer.displayName] == nil {
                let used = Set(self.peerCarIndex.values)
                let next = (1...).first { !used.contains($0) } ?? 1
                self.peerCarIndex[peer.displayName] = next
            }
        }
    }

    /// Tildel remote peer til en bil (bruges til forhåndstilmeldte peers)
    func assignPeer(_ peerId: String, carIndex: Int) {
        peerCarIndex[peerId] = carIndex
    }

    /// Start broadcasting state ~30Hz + send start-signal til clients
    func startBroadcasting() {
        // Send start-besked til alle clients
        let lobby = GameMessage.LobbyUpdate(
            players: [], trackName: nil, totalLaps: gameEngine.gameState.totalLaps, isStarting: true, isAR: false
        )
        session.sendToAll(.lobbyUpdate(lobby), reliable: true)

        broadcastTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.broadcastState()
        }
    }

    func stopBroadcasting() {
        broadcastTimer?.invalidate()
        broadcastTimer = nil
    }

    private func handleMessage(_ message: GameMessage, from peer: MCPeerID) {
        if case .throttleInput(let input) = message {
            if let carIndex = peerCarIndex[input.playerId],
               carIndex < gameEngine.carControllers.count {
                DispatchQueue.main.async {
                    self.gameEngine.carControllers[carIndex].isThrottlePressed = input.isPressed
                }
            }
        }
    }

    private func broadcastState() {
        let gs = gameEngine.gameState
        let cars = gameEngine.carControllers.enumerated().map { (index, c) in
            let peerId = peerCarIndex.first(where: { $0.value == index })?.key ?? "host"
            return GameMessage.CarState(
                playerId: peerId,
                progress: c.progress,
                speed: c.speed,
                lapCount: c.lapCount,
                isDisabled: c.flyOff.isDisabled,
                lane: c.lane
            )
        }

        let phaseInfo: GameMessage.PhaseInfo
        if let countdown = gs.countdownNumber {
            phaseInfo = .init(type: "countdown", countdown: countdown, winnerId: nil)
        } else if gs.isFinished {
            phaseInfo = .init(type: "finished", countdown: nil, winnerId: gs.playerWon ? "host" : nil)
        } else {
            phaseInfo = .init(type: "racing", countdown: nil, winnerId: nil)
        }

        let update = GameMessage.StateUpdate(cars: cars, raceTime: gs.raceTime, phase: phaseInfo)
        session.sendToAll(.stateUpdate(update), reliable: false)
    }
}
