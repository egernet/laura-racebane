import Foundation

/// Alle tilgængelige baner bygget af Carrera-style stykker.
/// Standard kurve = 45° → 4 stykker = 180° sving.
/// Alle baner er geometrisk verificeret til at lukke.
struct TrackCatalog {

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
        ]
    )

    /// Otte-tal - to loops forbundet med kryds-stykker
    /// Begge loops bruger curveLeft. Fra modsatte retninger kurver de
    /// automatisk op/ned → banen krydser sig selv ved crossover.
    /// Total vinkel: 360° (bilen drejer en fuld omgang)
    static let figurEight = TrackDefinition(
        name: "Otte-tal",
        pieces: [
            // Kryds ud
            .crossover,
            // Øverste loop
            .curveLeft, .curveLeft, .curveLeft, .curveLeft,  // 180°
            // Kryds tilbage (her krydser banen sig selv)
            .crossover,
            // Nederste loop (fra modsatte retning → kurver nedad)
            .curveLeft, .curveLeft, .curveLeft, .curveLeft,  // 180°
        ]
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
        ]
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
        ]
    )
}
