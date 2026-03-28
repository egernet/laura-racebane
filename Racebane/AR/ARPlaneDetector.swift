import ARKit

/// Hjælper til at tjekke AR-support
struct ARSupport {
    /// Tjek om enheden understøtter AR
    static var isSupported: Bool {
        ARWorldTrackingConfiguration.isSupported
    }

    /// Tjek om enheden har LiDAR og understøtter scene mesh reconstruction.
    /// Kræver iPhone 12 Pro+ eller iPad Pro med LiDAR.
    static var supportsSceneReconstruction: Bool {
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }
}
