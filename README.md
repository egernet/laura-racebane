# Racebane

Et slot car racing-spil til iOS lavet af Laura (10 år) med hjælp fra far.

Bygget med Swift, SceneKit og SwiftUI.

## Om spillet

Racebane er et klassisk racerbane-spil hvor biler kører på spor. Den eneste kontrol er gas - men pas på! Kører du for hurtigt i sving, flyver bilen af banen og du skal vente 2 sekunder.

## Funktioner

- 3D racerbane med SceneKit
- Flere baner med forskellig sværhedsgrad (Begynder Oval, Otte-tal, Grand Prix, Lauras Løkke)
- AI-modstander med tre sværhedsgrader
- Lokal multiplayer over WiFi via MultipeerConnectivity
- AR-mode: placer banen på dit bord med ARKit
- Syntetiseret lyd: motorlyd, eksplosioner, countdown og menu-musik
- Haptic feedback
- iPhone og iPad support

## Krav

- iOS 16.0+
- iPhone eller iPad
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Sådan bygger du

```bash
# Generer Xcode-projekt (skal køres først)
xcodegen generate

# Byg
xcodebuild -project Racebane.xcodeproj -scheme Racebane \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build
```

> **Bemærk:** `Racebane.xcodeproj/` genereres af XcodeGen fra `project.yml` og skal ikke committes.

## Sådan spiller du

1. Vælg en bane i menuen
2. Tryk og hold gas-knappen for at accelerere
3. Slip gas-knappen før sving for ikke at flyve af banen
4. Første bil over målstregen vinder!

## Projektstruktur

```
Racebane/
  App/           - SwiftUI entry point
  Game/          - GameEngine, CarController, AIController, SoundManager
  Track/         - TrackPiece, TrackPath, TrackBuilder, TrackCatalog
  Scene/         - RaceScene, CarNode, CameraRig
  UI/            - MenuView, HUDView, ThrottleButton, ResultView
  Multiplayer/   - Host/Client via MultipeerConnectivity
  AR/            - ARKit integration
  Resources/     - Models, Textures
plans/           - Udviklingsplaner
doc/             - Dokumentation
```

## Lavet med

- Swift & SceneKit
- SwiftUI
- ARKit
- MultipeerConnectivity
- AVAudioEngine (syntetiseret lyd)
- Claude Code
