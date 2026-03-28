import Foundation

/// Alle tilgængelige baner
struct TrackCatalog {

    static let allTracks: [TrackDefinition] = [
        beginnerOval,
        figurEight,
        grandPrix,
        laurasLoop
    ]

    /// Begynder Oval - let, brede sving
    static let beginnerOval = TrackDefinition(
        name: "Begynder Oval",
        segments: [
            .straight(length: 8.0),
            .curve(angle: .pi, radius: 3.0),
            .straight(length: 8.0),
            .curve(angle: .pi, radius: 3.0)
        ]
    )

    /// Otte-tal - kryds i midten, medium sværhedsgrad
    static let figurEight = TrackDefinition(
        name: "Otte-tal",
        segments: [
            .straight(length: 4.0),
            .curve(angle: .pi * 1.1, radius: 2.5),
            .straight(length: 3.0),
            .curve(angle: -.pi * 1.1, radius: 2.5),
            .straight(length: 4.0),
            .curve(angle: .pi * 1.1, radius: 2.5),
            .straight(length: 3.0),
            .curve(angle: -.pi * 1.1, radius: 2.5)
        ]
    )

    /// Grand Prix - hairpins, chicaner, svær
    static let grandPrix = TrackDefinition(
        name: "Grand Prix",
        segments: [
            .straight(length: 10.0),
            .curve(angle: .pi / 2, radius: 2.0),       // Skarpt sving 1
            .straight(length: 3.0),
            .curve(angle: .pi / 2, radius: 2.0),       // Sving 2
            .straight(length: 6.0),
            .curve(angle: .pi / 4, radius: 3.0),       // Let kurve
            .curve(angle: -.pi / 4, radius: 3.0),      // Chicane del 1
            .curve(angle: .pi / 4, radius: 3.0),       // Chicane del 2
            .straight(length: 4.0),
            .curve(angle: .pi * 0.75, radius: 1.5),    // Hairpin!
            .straight(length: 5.0),
            .curve(angle: .pi / 2, radius: 2.5),       // Bredt sving
            .straight(length: 3.0),
            .curve(angle: .pi / 3, radius: 2.0),
            .straight(length: 4.0),
            .curve(angle: .pi / 3 + 0.02, radius: 2.5) // Afsluttende sving
        ]
    )

    /// Lauras Løkke - sjov hjerteformet bane
    static let laurasLoop = TrackDefinition(
        name: "Lauras Løkke",
        segments: [
            // Højre halvdel af hjertet
            .straight(length: 3.0),
            .curve(angle: .pi * 0.8, radius: 2.5),
            .curve(angle: -.pi * 0.3, radius: 4.0),
            .straight(length: 2.0),
            .curve(angle: .pi * 0.5, radius: 1.5),
            // Spidsen
            .curve(angle: .pi * 0.5, radius: 1.5),
            .straight(length: 2.0),
            .curve(angle: -.pi * 0.3, radius: 4.0),
            .curve(angle: .pi * 0.8, radius: 2.5),
            .straight(length: 3.0),
            // Lukning
            .curve(angle: .pi * 0.2, radius: 3.0)
        ]
    )
}
