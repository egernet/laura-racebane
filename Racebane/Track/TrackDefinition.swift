import Foundation

// MARK: - Carrera-style bane-stykker

/// Standardiserede banestykker inspireret af Carrera racerbaner.
/// Standard kurve = 45° → 4 stykker = 180° sving, 8 stykker = fuld cirkel.
enum TrackPiece: Equatable {
    // Lige stykker
    case straight              // Standard (2.0m)
    case straightLong          // Langt (4.0m)
    case straightShort         // Kort (1.0m)

    // Standard kurver (45°, radius 2.5m)
    case curveLeft             // 45° venstre
    case curveRight            // 45° højre

    // Brede kurver (45°, radius 4.0m)
    case wideCurveLeft         // 45° venstre, bred
    case wideCurveRight        // 45° højre, bred

    /// Konverter til TrackSegment
    var segment: TrackSegment {
        switch self {
        case .straight:         return .straight(length: 2.0)
        case .straightLong:     return .straight(length: 4.0)
        case .straightShort:    return .straight(length: 1.0)

        case .curveLeft:        return .curve(angle:  rad(45), radius: 2.5)
        case .curveRight:       return .curve(angle: -rad(45), radius: 2.5)

        case .wideCurveLeft:    return .curve(angle:  rad(45), radius: 4.0)
        case .wideCurveRight:   return .curve(angle: -rad(45), radius: 4.0)
        }
    }

    /// Vinkelbidraget i grader
    var angleDegrees: Float {
        switch self {
        case .straight, .straightLong, .straightShort: return 0
        case .curveLeft, .wideCurveLeft:   return 45
        case .curveRight, .wideCurveRight: return -45
        }
    }

    private func rad(_ degrees: Float) -> Float {
        degrees * .pi / 180.0
    }
}

/// Lavniveau-segment (bruges af TrackPath)
enum TrackSegment {
    case straight(length: Float)
    case curve(angle: Float, radius: Float)
}

/// Komplet definition af en racerbane
struct TrackDefinition {
    let name: String
    let pieces: [TrackPiece]
    let laneCount: Int
    let laneWidth: Float
    let trackWidth: Float

    var segments: [TrackSegment] {
        pieces.map { $0.segment }
    }

    /// Total vinkelsum i grader
    var totalAngleDegrees: Float {
        pieces.reduce(0) { $0 + $1.angleDegrees }
    }

    init(name: String, pieces: [TrackPiece], laneCount: Int = 2, laneWidth: Float = 0.4, trackWidth: Float = 1.2) {
        self.name = name
        self.pieces = pieces
        self.laneCount = laneCount
        self.laneWidth = laneWidth
        self.trackWidth = trackWidth
    }
}
