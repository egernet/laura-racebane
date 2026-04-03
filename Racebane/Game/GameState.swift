import UIKit

/// Race-tilstand
enum RacePhase {
    case countdown(remaining: Int)  // 3, 2, 1
    case racing
    case finished
}

/// Resultat for én bil i racet
struct CarRaceResult: Identifiable {
    let id: Int
    let name: String
    let color: UIColor
    var lap: Int = 0
    var finished: Bool = false
    var totalTime: Float = 0
    var bestLap: Float = .infinity
}

/// Delt state for et race
class GameState: ObservableObject {
    @Published var phase: RacePhase = .countdown(remaining: 3)
    @Published var raceTime: Float = 0
    @Published var totalLaps: Int = 3
    @Published var carResults: [CarRaceResult] = []
    @Published var playerIndex: Int = 0

    /// Nulstil til nyt race
    func reset(laps: Int = 3) {
        phase = .countdown(remaining: 3)
        raceTime = 0
        totalLaps = laps
        for i in carResults.indices {
            carResults[i].lap = 0
            carResults[i].finished = false
            carResults[i].totalTime = 0
            carResults[i].bestLap = .infinity
        }
    }

    // MARK: - Computed properties (bagudkompatibilitet)

    var playerLap: Int {
        guard playerIndex < carResults.count else { return 0 }
        return carResults[playerIndex].lap
    }

    var playerFinished: Bool {
        guard playerIndex < carResults.count else { return false }
        return carResults[playerIndex].finished
    }

    var playerWon: Bool {
        guard playerIndex < carResults.count else { return false }
        let playerTime = carResults[playerIndex].totalTime
        // Spilleren vandt hvis ingen andre var hurtigere
        return carResults[playerIndex].finished &&
            !carResults.enumerated().contains { (i, r) in
                i != playerIndex && r.finished && r.totalTime < playerTime
            }
    }

    var playerTotalTime: Float {
        guard playerIndex < carResults.count else { return 0 }
        return carResults[playerIndex].totalTime
    }

    var playerBestLap: Float {
        guard playerIndex < carResults.count else { return .infinity }
        return carResults[playerIndex].bestLap
    }

    /// Sorterede resultater (hurtigste først, uafsluttede sidst)
    var rankedResults: [CarRaceResult] {
        carResults.sorted { a, b in
            if a.finished && !b.finished { return true }
            if !a.finished && b.finished { return false }
            if a.finished && b.finished { return a.totalTime < b.totalTime }
            return a.lap > b.lap
        }
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
