import ARKit

/// Hjælper til at tjekke AR-support
struct ARSupport {
    /// Tjek om enheden understøtter AR
    static var isSupported: Bool {
        ARWorldTrackingConfiguration.isSupported
    }
}
