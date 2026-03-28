# Racebane - Claude Code Guide

## Projekt

Slot car racing-spil til iOS (iPhone/iPad) bygget med Swift og SceneKit. Lavet af Laura (10 år) med hjælp fra far. Kommunikation foregår på dansk.

## Bygge og køre

```bash
# Generer Xcode-projekt (SKAL køres efter ændringer i project.yml eller nye filer)
xcodegen generate

# Byg
xcodebuild -project Racebane.xcodeproj -scheme Racebane -destination 'generic/platform=iOS Simulator' -configuration Debug build

# Kør tests
xcodebuild test -project Racebane.xcodeproj -scheme Racebane -destination 'platform=iOS Simulator,id=6B3DAAEB-409F-4CD8-94B3-B3BF1D961EAA' -only-testing:RacebaneTests
```

## Vigtige regler

- **Racebane.xcodeproj/ skal IKKE committes** - det genereres af XcodeGen fra `project.yml`
- **Overhead-kamera** som standard (Carrera-style oppefra), ikke chase-kamera
- **Commit efter hver gennemført fase**
- Plans i `/plans`, docs i `/doc`, skills i `/skills`

## Arkitektur

### Banestykker (Carrera-style)
Baner bygges af standardiserede `TrackPiece` stykker (45° kurver):
- 4 kurvesektioner = 180° sving
- Vinkelsum = 360° for lukkede baner (0° for otte-tal)
- Modstående sider skal have samme længde
- Brede kurver (R=4.0) på modstående hjørner for balance
- `TrackValidator` verificerer at baner lukker korrekt

### Fysik
- Bilen er en 1D-entitet (progress `t` langs sporet) renderet i 3D
- Eneste kontrol: gas (throttle)
- Afkørsel: `a_c = v²/r > threshold` → 2 sek. straf
- `TrackPath` sampler Bezier-kurver til lookup-tabel

### Game loop
`SCNSceneRendererDelegate` → `GameEngine.renderer(updateAtTime:)` → opdater `CarController`s → lookup position fra `TrackPath` → opdater `CarNode`s

### Multiplayer
Host-autoritativ via MultipeerConnectivity. Clients sender kun throttle-input. Host broadcaster state ~30Hz.

## Mappestruktur

```
Racebane/
  App/           - SwiftUI entry point, ContentView
  Game/          - GameEngine, GameState, CarController, AIController, FlyOffController
  Track/         - TrackPiece, TrackDefinition, TrackPath, TrackBuilder, TrackCatalog, TrackValidator
  Scene/         - RaceScene, CarNode, CameraRig
  UI/            - RaceView, HUDView, ThrottleButton, MenuView, LobbyView, CountdownView, ResultView, PieceCatalogView
  Multiplayer/   - SessionManager, MessageProtocol, HostEngine, ClientEngine
  AR/            - (Fase 8 - ikke implementeret endnu)
  Extensions/    - SCNVector3+Math
  Resources/     - Models, Textures, Sounds
RacebaneTests/   - TrackValidatorTests
```

## Implementeringsfaser

- [x] Fase 1: Projektskelett og statisk bane
- [x] Fase 2: Bil på bane med gaskontrol
- [x] Fase 3: Kurve-fysik og afkørsel
- [x] Fase 4: Flere baner og banevælger
- [x] Fase 5: Race-struktur (nedtælling, AI, resultat)
- [x] Fase 6: Lokal multiplayer
- [x] Fase 7: Polish og tilgængelighed
- [x] Fase 8: AR Mode
