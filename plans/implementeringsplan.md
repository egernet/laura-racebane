# Racebane - Implementeringsplan

## Context

Lauras (10 år) racerbane-spil til iOS. Et klassisk slot car racing-spil bygget med Swift og SceneKit. Biler kører på spor - eneste kontrol er gas. Kører man for hurtigt i sving, flyver bilen af banen (2 sek. straf). Multiplayer over lokalt netværk. AR som sidste fase.

---

## Projektstruktur

```
Racebane/
  Racebane.xcodeproj
  Racebane/
    App/
      RacebaneApp.swift
      ContentView.swift
    Game/
      GameEngine.swift            -- Hoved-gameloop (SCNSceneRendererDelegate)
      GameState.swift             -- Delt state-model
      CarController.swift         -- Hastighed/fysik per bil
      FlyOffController.swift      -- Afkørsel-animation + straftimer
    Track/
      TrackDefinition.swift       -- Segmenter: .straight(length), .curve(angle, radius)
      TrackPath.swift             -- Bezier-sampling, lookup-tabel (KRITISK fil)
      TrackBuilder.swift          -- Bygger SCNNodes fra TrackDefinition
      TrackCatalog.swift          -- Foruddefinerede baner
    Scene/
      RaceScene.swift             -- SCNScene: lys, miljø, bane
      CarNode.swift               -- SCNNode for bil
      TrackNode.swift             -- SCNNode for bane
      CameraRig.swift             -- Kameraer (chase, overhead)
    UI/
      RaceView.swift              -- SwiftUI + SCNView
      ThrottleButton.swift        -- Gas-knap
      HUDView.swift               -- Speedometer, omgange, position
      LobbyView.swift             -- Multiplayer-lobby
      MenuView.swift              -- Hovedmenu
    Multiplayer/
      SessionManager.swift        -- MultipeerConnectivity wrapper
      MessageProtocol.swift       -- Codable beskedtyper
      HostEngine.swift            -- Host: autoritativ gameloop
      ClientEngine.swift          -- Client: input + interpolation
    AR/
      ARRaceView.swift            -- ARSCNView integration
      ARPlaneDetector.swift       -- Fladedetektering
    Resources/
      Models/
      Textures/
      Sounds/
    Extensions/
      SCNVector3+Math.swift
      BezierPath+Sampling.swift
  plans/
  doc/
  skills/
  README.md
```

---

## Fase 1: Projektskelett og statisk bane

**Mål**: Xcode-projekt der kompilerer og viser en 3D-scene med en oval bane.

- Opret Xcode-projekt (iOS 16+, SwiftUI, iPhone + iPad)
- Opret mappestruktur + `/plans`, `/doc`, `/skills`, `README.md`
- `TrackDefinition.swift` - segmenter (straight/curve) og bane-definition
- `TrackPath.swift` - Bezier-sampling → array af PathPoints (position, tangent, normal, kurvaturradius)
- `TrackBuilder.swift` - generer SCNNode-geometri for banen (mørk grå med hvide striber, rød/hvide kantsten)
- `RaceScene.swift` - SCNScene med lys, grøn grundflade, blå himmel, bane-node
- `RaceView.swift` - SwiftUI view med SCNView
- `CameraRig.swift` - statisk overhead-kamera

**Resultat**: App starter og viser en farverig 3D oval bane set oppefra.

---

## Fase 2: Bil på bane med gaskontrol

**Mål**: En bil der kører langs sporet når man trykker gas.

- `CarNode.swift` - SCNBox med farve (senere erstat med model)
- `CarController.swift` - progress (0..1), speed, acceleration/drag, opdater position fra TrackPath
- `ThrottleButton.swift` - stor farverig cirkel-knap, touch-down/up
- `GameEngine.swift` - SCNSceneRendererDelegate, kalder CarController.update() per frame
- `CameraRig.swift` - chase-kamera der følger bilen

**Resultat**: Bil kører rundt på banen med gas-knap. Kamera følger bilen.

---

## Fase 3: Kurve-fysik og afkørsel

**Mål**: Biler flyver af banen ved for høj fart i sving. 2 sek. straf.

- Centripetal kraft: `a_c = v² / r`. Overstiger threshold → afkørsel
- `FlyOffController.swift` - afkørselsanimation (SCNPhysicsBody.dynamic + impuls), 2 sek. timer, respawn
- `HUDView.swift` - speedometer (grøn/gul/rød zone), "STRAF" overlay
- Motorsound der stiger i tonehøjde med hastighed
- Tuning af feel: acceleration, drag, maxspeed, afkørsel-threshold

**Resultat**: Komplet single-player slot car-oplevelse med risiko/belønning.

---

## Fase 4: Flere baner og banevælger

**Mål**: 3-4 baner at vælge imellem.

- `TrackCatalog.swift`:
  - "Begynder Oval" - let, brede sving
  - "Otte-tal" - kryds med bro, medium
  - "Grand Prix" - hairpins, chicaner, svær
  - "Lauras Løkke" - sjov specialform (hjerte/stjerne)
- `MenuView.swift` - hovedmenu med banevælger og top-down previews
- Navigation: Menu → Banevælg → Race
- Højdeforskelle i TrackBuilder (bro til otte-tal)

**Resultat**: Vælg mellem flere baner med forskellig sværhedsgrad.

---

## Fase 5: Race-struktur og polish

**Mål**: Nedtælling, omgange, resultat, AI-modstander.

- Race-flow: 3-2-1-GO nedtælling → race (omgangstæller) → resultatskærm med konfetti
- HUD: omgangstæller, racetimer, minimap
- AI-bil: variabel målhastighed per segment + tilfældighed
- Bilvælger: farver (pink, lilla, turkis, orange, lime)
- Partikler: dæk-røg nær grænsen, gnistspor
- Lyd: nedtælling, jubel, crash, baggrundsmusik

**Resultat**: Komplet single-player racerspil med AI-modstander og polish.

---

## Fase 6: Lokal multiplayer

**Mål**: 2+ spillere over lokalt netværk.

- `MessageProtocol.swift` - Codable beskeder: ThrottleInput, GameStateUpdate, GameEvent
- `SessionManager.swift` - MCSession/Advertiser/Browser wrapper, service "racebane"
- `LobbyView.swift` - se hvem der er forbundet, host vælger bane/omgange
- `HostEngine.swift` - modtager input, kører alle biler, broadcaster state ~30 Hz
- `ClientEngine.swift` - sender input, interpolerer modtagne positioner
- Flere CarNodes med forskellige farver/spor
- Broadcast-kamera (overhead) som standard i multiplayer
- Håndter disconnect gracefully

**Resultat**: Multiplayer slot car racing over WiFi.

---

## Fase 7: Polish og tilgængelighed

**Mål**: Gør spillet lækkert og robust.

- Haptic feedback (gas, crash, finish)
- Kamera-shake ved afkørsel
- Tilgængelighed: VoiceOver, Dynamic Type, high contrast
- Indstillinger: sværhedsgrad (justerer afkørsels-threshold), lyd, kamera
- "Fri kørsel" mode
- Sejrsanimation: konfetti, fyrværkeri, æresomgang
- Sjove bilnavne ("Lyn-Laura", "Turbo Star", "Pink Raket")
- App-ikon og launch screen
- README.md, /doc dokumentation

**Resultat**: Poleret, sjovt, tilgængeligt spil.

---

## Fase 8: AR Mode (sidste fase)

**Mål**: Placer banen på et rigtigt bord i AR.

- `ARRaceView.swift` - ARSCNView med horisontal plane detection
- `ARPlaneDetector.swift` - vis indikator for placeringsmuligheder
- Tap for at placere bane, pinch for at skalere
- Genbrug RaceScene (tilføj som child af AR anchor)
- Automatisk lyssætning fra AR-miljø
- Multiplayer i AR: hver enhed placerer banen separat, delt game state
- HUD og gas-knap som overlay over kamerafeed
- Toggle i menu: "Spil i AR" vs "Spil på skærm"
- Kræver A12+ chip; detektér og deaktivér på ældre enheder

**Resultat**: Fuld AR-support - placer racerbanen på køkkenbordet.

---

## Tekniske nøglepunkter

- **Banens matematik**: Bilen er en 1D-entitet (progress `t` langs sporet) renderet i 3D. TrackPath.swift sampler Bezier-kurver til en lookup-tabel. Dette er den vigtigste kode.
- **Afkørsel**: `a_c = v² / r` mod threshold. Easy: 1.5x threshold, Hard: 0.75x.
- **Multiplayer**: Host er autoritativ. Clients sender kun throttle-input. Host broadcaster state. Minimal båndbredde.
- **Frameloop**: SCNSceneRendererDelegate → opdater CarControllers → lookup position fra TrackPath → opdater CarNodes → opdater kamera.

## Verifikation

- **Fase 1**: App kompilerer og viser bane i simulator
- **Fase 2**: Bil kører rundt ved tryk på gas i simulator
- **Fase 3**: Bil flyver af ved for høj fart, 2 sek. pause, respawn
- **Fase 4**: Kan vælge mellem baner i menu
- **Fase 5**: Komplet race med nedtælling, AI, resultat
- **Fase 6**: To simulatorer på samme netværk kan race mod hinanden
- **Fase 7**: Test haptics og tilgængelighed på fysisk enhed
- **Fase 8**: Test AR-placering på fysisk enhed med A12+ chip
