import Foundation

/// Alle beskedtyper mellem host og client
enum GameMessage: Codable {
    case throttleInput(ThrottleInput)
    case stateUpdate(StateUpdate)
    case gameEvent(GameEvent)
    case lobbyUpdate(LobbyUpdate)

    // MARK: - Beskedtyper

    struct ThrottleInput: Codable {
        let playerId: String
        let isPressed: Bool
    }

    struct CarState: Codable {
        let playerId: String
        let progress: Float
        let speed: Float
        let lapCount: Int
        let isDisabled: Bool
        let lane: Int
    }

    struct StateUpdate: Codable {
        let cars: [CarState]
        let raceTime: Float
        let phase: PhaseInfo
    }

    struct PhaseInfo: Codable {
        let type: String      // "countdown", "racing", "finished"
        let countdown: Int?   // Kun for countdown
        let winnerId: String? // Kun for finished
    }

    struct GameEvent: Codable {
        let type: EventType
        let playerId: String

        enum EventType: String, Codable {
            case flyOff
            case lapComplete
            case raceStart
            case raceEnd
        }
    }

    struct LobbyUpdate: Codable {
        let players: [PlayerInfo]
        let trackName: String?
        let totalLaps: Int
        let isStarting: Bool
    }

    struct PlayerInfo: Codable {
        let id: String
        let name: String
        let colorIndex: Int
        let isHost: Bool
        let isReady: Bool
    }
}
