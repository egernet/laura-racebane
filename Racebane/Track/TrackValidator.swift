import Foundation

/// Resultat af at simulere en bane
struct TrackEndState {
    let posX: Float
    let posZ: Float
    let heading: Float
    let positionError: Float
    let headingError: Float
    let totalAngleDegrees: Float

    var isClosed: Bool {
        positionError < 0.15 && headingError < 0.05
    }
}

/// Validerer baner bygget af standardstykker
struct TrackValidator {

    /// Simuler segmenterne og find slutposition/heading
    static func simulate(segments: [TrackSegment]) -> TrackEndState {
        var posX: Float = 0
        var posZ: Float = 0
        var heading: Float = 0

        for segment in segments {
            switch segment {
            case .straight(let length):
                posX += cos(heading) * length
                posZ += sin(heading) * length

            case .curve(let angle, let radius):
                let dir: Float = angle > 0 ? 1 : -1
                let cX = posX + (-sin(heading) * dir) * radius
                let cZ = posZ + (cos(heading) * dir) * radius
                heading += angle
                posX = cX + (sin(heading) * dir) * radius
                posZ = cZ + (-cos(heading) * dir) * radius
            }
        }

        let positionError = sqrt(posX * posX + posZ * posZ)
        let headingError = abs(normalizeAngle(heading))

        return TrackEndState(
            posX: posX,
            posZ: posZ,
            heading: heading,
            positionError: positionError,
            headingError: headingError,
            totalAngleDegrees: heading * 180 / .pi
        )
    }

    /// Simuler en TrackDefinition (convenience)
    static func simulate(definition: TrackDefinition) -> TrackEndState {
        simulate(segments: definition.segments)
    }

    /// Valider at en banes vinkler summerer korrekt
    /// For en normal lukket bane: 360°
    /// For otte-tal: 0° (to modsatrettede loops)
    static func validateAngleSum(definition: TrackDefinition) -> Bool {
        let total = definition.totalAngleDegrees
        // Accepter 360° (normal loop) eller 0° (figure-8)
        return abs(total - 360) < 0.1 || abs(total) < 0.1
    }

    /// Fuld validering: vinkler + positions-lukning
    static func isValid(definition: TrackDefinition) -> Bool {
        guard validateAngleSum(definition: definition) else { return false }
        let state = simulate(definition: definition)
        return state.isClosed
    }

    /// Normaliser vinkel til (-pi, pi]
    static func normalizeAngle(_ angle: Float) -> Float {
        var a = angle.truncatingRemainder(dividingBy: 2 * .pi)
        if a > .pi { a -= 2 * .pi }
        if a <= -.pi { a += 2 * .pi }
        return a
    }
}
