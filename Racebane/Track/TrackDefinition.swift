import Foundation

/// Et segment af racerbanen
enum TrackSegment {
    /// Lige stykke med en given længde i meter
    case straight(length: Float)
    /// Sving med vinkel (i radianer) og radius i meter.
    /// Positiv vinkel = sving til venstre, negativ = højre
    case curve(angle: Float, radius: Float)
}

/// Komplet definition af en racerbane
struct TrackDefinition {
    let name: String
    let segments: [TrackSegment]
    let laneCount: Int
    let laneWidth: Float
    let trackWidth: Float

    init(name: String, segments: [TrackSegment], laneCount: Int = 2, laneWidth: Float = 0.4, trackWidth: Float = 1.2) {
        self.name = name
        self.segments = segments
        self.laneCount = laneCount
        self.laneWidth = laneWidth
        self.trackWidth = trackWidth
    }

}
