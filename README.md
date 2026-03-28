# Racebane

Et slot car racing-spil til iOS lavet af Laura (10 år).

## Om spillet

Racebane er et klassisk racerbane-spil hvor biler kører på spor. Den eneste kontrol er gas - men pas på! Kører du for hurtigt i sving, flyver bilen af banen og du skal vente 2 sekunder.

## Funktioner

- 3D racerbane med SceneKit
- Flere baner med forskellig sværhedsgrad
- AI-modstander
- Lokal multiplayer over WiFi
- AR-mode: placer banen på dit bord
- iPhone og iPad support

## Krav

- iOS 16.0+
- iPhone eller iPad
- Xcode 15+

## Sådan bygger du

1. Åbn `Racebane.xcodeproj` i Xcode
2. Vælg din enhed eller simulator
3. Tryk Run (Cmd+R)

## Sådan spiller du

1. Vælg en bane
2. Tryk og hold gas-knappen for at accelerere
3. Slip gas-knappen før sving for ikke at flyve af banen
4. Første bil over målstregen vinder!

## Projektstruktur

- `Racebane/` - Kildekode
  - `App/` - App entry point
  - `Game/` - Spillogik og fysik
  - `Track/` - Banedefinitioner og -bygning
  - `Scene/` - SceneKit scener og noder
  - `UI/` - SwiftUI views
  - `Multiplayer/` - Netværkskode
  - `AR/` - Augmented Reality
- `plans/` - Udviklingsplaner
- `doc/` - Dokumentation
- `skills/` - Skills
