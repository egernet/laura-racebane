import Foundation

/// Alle tilgængelige baner bygget af Carrera-style stykker.
/// Standard kurve = 45° → 4 stykker = 180° sving.
/// Alle baner er geometrisk verificeret til at lukke.
struct TrackCatalog {

    static func track(named name: String) -> TrackDefinition? {
        allTracks.first { $0.name == name }
    }

    static let allTracks: [TrackDefinition] = [
        beginnerOval,
        figurEight,
        grandPrix,
        laurasLoop
    ]

    /// Begynder Oval - simpel oval
    /// 4 kurver (180°) + lige + 4 kurver (180°) + lige = 360°
    static let beginnerOval = TrackDefinition(
        name: "Begynder Oval",
        pieces: [
            .straightLong,
            .curveLeft, .curveLeft, .curveLeft, .curveLeft,  // 180°
            .straightLong,
            .curveLeft, .curveLeft, .curveLeft, .curveLeft,  // 180°
        ],
        laneCount: 4,
        trackWidth: 2.0
    )

    /// Otte-tal - to fulde cirkler der mødes ved krydspunktet
    /// Øverste cirkel: 8x curveLeft (360° mod-uret)
    /// Nedre cirkel: 8x curveRight (360° med-uret)
    /// Begge cirkler tangerer ved (0,0) → rigtigt 8-form set oppefra.
    /// Bro ved progress=0.5 (krydspunktet midt i banen).
    static let figurEight = TrackDefinition(
        name: "Otte-tal",
        pieces: [
            // Øverste loop (mod-uret, 360°)
            .curveLeft, .curveLeft, .curveLeft, .curveLeft,
            .curveLeft, .curveLeft, .curveLeft, .curveLeft,
            // Nedre loop (med-uret, -360°) — krydser øverste ved bro
            .curveRight, .curveRight, .curveRight, .curveRight,
            .curveRight, .curveRight, .curveRight, .curveRight,
        ],
        laneCount: 4,
        trackWidth: 2.0,
        bridgeCenterProgress: 0.5,
        bridgeRampLength: 2.5,
        bridgeHeight: 0.45
    )

    /// Grand Prix - rektangulær bane
    /// 4 hjørner á 2 kurver (90°) = 360°
    /// Modstående sider har identiske lige stykker
    static let grandPrix = TrackDefinition(
        name: "Grand Prix",
        pieces: [
            // Side 1 (lang)
            .straightLong, .straightLong, .straight,
            // Hjørne 1
            .curveLeft, .curveLeft,                          // 90°
            // Side 2 (kort)
            .straight, .straight,
            // Hjørne 2
            .curveLeft, .curveLeft,                          // 90°
            // Side 3 (lang - matcher side 1)
            .straight, .straightLong, .straightLong,
            // Hjørne 3
            .curveLeft, .curveLeft,                          // 90°
            // Side 4 (kort - matcher side 2)
            .straight, .straight,
            // Hjørne 4
            .curveLeft, .curveLeft,                          // 90°
        ],
        laneCount: 4,
        trackWidth: 2.0
    )

    /// Lauras Løkke - rektangel med brede og stramme sving
    /// Brede kurver på MODSTÅENDE hjørner (1,3) og stramme på (2,4)
    /// → radierne ophæver hinanden og banen lukker
    static let laurasLoop = TrackDefinition(
        name: "Lauras Løkke",
        pieces: [
            // Side 1
            .straightLong, .straight,
            // Hjørne 1 (bredt)
            .wideCurveLeft, .wideCurveLeft,              // 90°
            // Side 2
            .straight, .straight,
            // Hjørne 2 (stramt)
            .curveLeft, .curveLeft,                      // 90°
            // Side 3 (matcher side 1)
            .straight, .straightLong,
            // Hjørne 3 (bredt)
            .wideCurveLeft, .wideCurveLeft,              // 90°
            // Side 4 (matcher side 2)
            .straight, .straight,
            // Hjørne 4 (stramt)
            .curveLeft, .curveLeft,                      // 90°
        ],
        laneCount: 4,
        trackWidth: 2.0
    )
}
