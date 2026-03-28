import Foundation
import SceneKit
import MultipeerConnectivity

/// Client-side: sender input, modtager og interpolerer state fra host
class ClientEngine {
    let session: SessionManager
    let playerId: String
    var carNodes: [String: CarNode] = [:]  // playerId -> CarNode
    var trackPath: TrackPath?
    var onStateUpdate: ((GameMessage.StateUpdate) -> Void)?

    private var lastStates: [String: GameMessage.CarState] = [:]

    init(session: SessionManager, playerId: String) {
        self.session = session
        self.playerId = playerId
        setupMessageHandling()
    }

    /// Send throttle input til host
    func sendThrottle(isPressed: Bool) {
        let input = GameMessage.ThrottleInput(playerId: playerId, isPressed: isPressed)
        session.sendToAll(.throttleInput(input), reliable: true)
    }

    // MARK: - Private

    private func setupMessageHandling() {
        session.onMessageReceived = { [weak self] message, _ in
            switch message {
            case .stateUpdate(let update):
                self?.applyState(update)
            default:
                break
            }
        }
    }

    private func applyState(_ update: GameMessage.StateUpdate) {
        guard let path = trackPath else { return }

        for carState in update.cars {
            // Opdater bilposition fra host state
            if let carNode = carNodes[carState.playerId] {
                let point = path.pointAt(progress: carState.progress)
                let laneOffset = SCNFloat(Float(carState.lane) * 0.4 - 0.2)
                let position = point.position + point.right * laneOffset

                // Blød interpolation
                let t: SCNFloat = 0.3
                carNode.position = SCNVector3(
                    carNode.position.x + (position.x - carNode.position.x) * t,
                    0,
                    carNode.position.z + (position.z - carNode.position.z) * t
                )

                let angle = atan2(point.tangent.x, point.tangent.z)
                carNode.eulerAngles.y = Float(angle) + .pi
                carNode.opacity = carState.isDisabled ? 0.4 : 1.0
            }

            lastStates[carState.playerId] = carState
        }

        onStateUpdate?(update)
    }
}
