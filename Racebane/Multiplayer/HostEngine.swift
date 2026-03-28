import Foundation
import MultipeerConnectivity

/// Host-side spilmotor: modtager input, kører fysik, broadcaster state
class HostEngine {
    let session: SessionManager
    let gameEngine: GameEngine
    private var playerPeerMap: [String: Int] = [:] // peerId -> carController index
    private var broadcastTimer: Timer?

    init(session: SessionManager, gameEngine: GameEngine) {
        self.session = session
        self.gameEngine = gameEngine
        setupMessageHandling()
    }

    /// Tildel en spiller til et car-controller index
    func assignPlayer(_ peerId: String, carIndex: Int) {
        playerPeerMap[peerId] = carIndex
    }

    /// Start broadcasting af game state ~30 Hz
    func startBroadcasting() {
        broadcastTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.broadcastState()
        }
    }

    func stopBroadcasting() {
        broadcastTimer?.invalidate()
        broadcastTimer = nil
    }

    // MARK: - Private

    private func setupMessageHandling() {
        session.onMessageReceived = { [weak self] message, peer in
            self?.handleMessage(message, from: peer)
        }
    }

    private func handleMessage(_ message: GameMessage, from peer: MCPeerID) {
        switch message {
        case .throttleInput(let input):
            // Anvend throttle input på den rigtige bil
            if let carIndex = playerPeerMap[input.playerId],
               carIndex < gameEngine.carControllers.count {
                gameEngine.carControllers[carIndex].isThrottlePressed = input.isPressed
            }
        default:
            break
        }
    }

    private func broadcastState() {
        let cars = gameEngine.carControllers.enumerated().map { (index, controller) in
            GameMessage.CarState(
                playerId: playerPeerMap.first(where: { $0.value == index })?.key ?? "host",
                progress: controller.progress,
                speed: controller.speed,
                lapCount: controller.lapCount,
                isDisabled: controller.flyOff.isDisabled,
                lane: controller.lane
            )
        }

        let phaseInfo: GameMessage.PhaseInfo
        let gs = gameEngine.gameState
        if let countdown = gs.countdownNumber {
            phaseInfo = GameMessage.PhaseInfo(type: "countdown", countdown: countdown, winnerId: nil)
        } else if gs.isFinished {
            let winnerId = gs.playerWon ? "host" : "ai"
            phaseInfo = GameMessage.PhaseInfo(type: "finished", countdown: nil, winnerId: winnerId)
        } else {
            phaseInfo = GameMessage.PhaseInfo(type: "racing", countdown: nil, winnerId: nil)
        }

        let update = GameMessage.StateUpdate(
            cars: cars,
            raceTime: gs.raceTime,
            phase: phaseInfo
        )

        session.sendToAll(.stateUpdate(update), reliable: false)
    }
}
