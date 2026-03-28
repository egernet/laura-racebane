import Foundation

/// Race-tilstand
enum RacePhase {
    case countdown(remaining: Int)  // 3, 2, 1
    case racing
    case finished
}

/// Delt state for et race
class GameState: ObservableObject {
    @Published var phase: RacePhase = .countdown(remaining: 3)
    @Published var raceTime: Float = 0
    @Published var totalLaps: Int = 3
    @Published var playerLap: Int = 0
    @Published var aiLap: Int = 0
    @Published var playerFinished: Bool = false
    @Published var aiFinished: Bool = false
    @Published var playerBestLap: Float = .infinity
    @Published var playerTotalTime: Float = 0
    @Published var aiTotalTime: Float = 0
    @Published var playerWon: Bool = false

    /// Nulstil til nyt race
    func reset(laps: Int = 3) {
        phase = .countdown(remaining: 3)
        raceTime = 0
        totalLaps = laps
        playerLap = 0
        aiLap = 0
        playerFinished = false
        aiFinished = false
        playerBestLap = .infinity
        playerTotalTime = 0
        aiTotalTime = 0
        playerWon = false
    }

    var isRacing: Bool {
        if case .racing = phase { return true }
        return false
    }

    var isFinished: Bool {
        if case .finished = phase { return true }
        return false
    }

    var countdownNumber: Int? {
        if case .countdown(let n) = phase { return n }
        return nil
    }
}
