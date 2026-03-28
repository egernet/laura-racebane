import UIKit

/// Haptic feedback til spilhændelser
class HapticManager {
    static let shared = HapticManager()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    var isEnabled: Bool = true

    private init() {
        lightImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
    }

    /// Let puls når gas trykkes
    func throttlePress() {
        guard isEnabled else { return }
        lightImpact.impactOccurred()
    }

    /// Hårdt slag ved afkørsel
    func flyOff() {
        guard isEnabled else { return }
        heavyImpact.impactOccurred()
    }

    /// Omgangs-feedback
    func lapComplete() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }

    /// Race slut
    func raceFinished(won: Bool) {
        guard isEnabled else { return }
        notification.notificationOccurred(won ? .success : .error)
    }

    /// Nedtælling-tick
    func countdownTick() {
        guard isEnabled else { return }
        lightImpact.impactOccurred()
    }

    /// KØR! signal
    func go() {
        guard isEnabled else { return }
        heavyImpact.impactOccurred()
    }
}
