import Foundation
import SceneKit

/// Client-side: sender gas-input, modtager og viser bilpositioner fra host
class ClientEngine: ObservableObject {
    let session: SessionManager
    let playerId: String

    @Published var phase: String = "waiting"  // waiting, countdown, racing, finished
    @Published var countdown: Int = 3
    @Published var raceTime: Float = 0
    @Published var playerSpeed: Float = 0
    @Published var playerLap: Int = 0
    @Published var isPlayerDisabled: Bool = false
    @Published var gameStarted: Bool = false
    @Published var winnerId: String?

    var carNodes: [String: CarNode] = [:]
    var trackPath: TrackPath?
    private var prevDisabledStates: [String: Bool] = [:]

    init(session: SessionManager, playerId: String) {
        self.session = session
        self.playerId = playerId

        session.onMessageReceived = { [weak self] message, _ in
            DispatchQueue.main.async {
                self?.handleMessage(message)
            }
        }
    }

    /// Send gas-input til host
    func sendThrottle(isPressed: Bool) {
        let input = GameMessage.ThrottleInput(playerId: playerId, isPressed: isPressed)
        session.sendToAll(.throttleInput(input), reliable: true)
    }

    private func handleMessage(_ message: GameMessage) {
        switch message {
        case .lobbyUpdate(let lobby):
            if lobby.isStarting {
                gameStarted = true
            }

        case .stateUpdate(let update):
            raceTime = update.raceTime

            // Opdater fase
            phase = update.phase.type
            if let c = update.phase.countdown { countdown = c }
            winnerId = update.phase.winnerId

            // Opdater bilpositioner
            guard let path = trackPath else { return }
            for carState in update.cars {
                let wasDisabled = prevDisabledStates[carState.playerId] ?? false
                if let node = carNodes[carState.playerId] {
                    if !wasDisabled && carState.isDisabled {
                        node.playFlyOffAnimation()
                    } else if wasDisabled && !carState.isDisabled {
                        node.resetFromFlyOff()
                    }

                    let point = path.pointAt(progress: carState.progress)
                    let laneOffset = SCNFloat(Float(carState.lane) * 0.4 - 0.2)
                    let pos = point.position + point.right * laneOffset

                    // Interpoler position
                    let t: SCNFloat = 0.3
                    node.position = SCNVector3(
                        node.position.x + (pos.x - node.position.x) * t,
                        0,
                        node.position.z + (pos.z - node.position.z) * t
                    )
                    let angle = atan2(point.tangent.x, point.tangent.z)
                    node.eulerAngles.y = Float(angle) + .pi
                    node.opacity = carState.isDisabled ? 0.4 : 1.0
                }
                prevDisabledStates[carState.playerId] = carState.isDisabled

                // Gem spillerens egne data til HUD
                if carState.playerId == playerId {
                    playerSpeed = carState.speed
                    playerLap = carState.lapCount
                    isPlayerDisabled = carState.isDisabled
                }
            }

        default:
            break
        }
    }
}
