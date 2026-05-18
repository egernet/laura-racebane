#!/usr/bin/env bash
# Capture App Store screenshots from the booted iPad Simulator.
#
# Usage:
#   ./scripts/capture-screenshots.sh
#
# The script walks you through 6 scenes, one at a time. For each scene:
#   1. Read the on-screen instruction
#   2. Navigate the app in the Simulator to match
#   3. Press Enter — the screenshot is saved to ./screenshots/
#
# Requirements:
#   - An iPad Simulator must be booted with Racebane running
#   - For App Store: must be 13" iPad Pro (2752x2064)
#     Recommended device: "iPad Pro 13-inch (M4)"
#   - For iPhone screenshots: boot iPhone 15 Pro Max (2796x1290) separately
#     and re-run the script.

set -euo pipefail

OUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/screenshots"
mkdir -p "$OUT_DIR"

# --- Check that a Simulator is booted ---------------------------------------

BOOTED_LINE="$(xcrun simctl list devices booted | grep -E '\(Booted\)' || true)"
if [[ -z "$BOOTED_LINE" ]]; then
    echo "FEJL: Ingen Simulator er booted."
    echo "       Åbn Xcode → kør Racebane på en iPad Simulator først."
    exit 1
fi

echo "Booted simulator: $BOOTED_LINE"

# Warn if device doesn't look like a 13" iPad or an iPhone Pro Max
if ! echo "$BOOTED_LINE" | grep -qiE '13-inch|13"|Pro Max'; then
    echo ""
    echo "ADVARSEL: Det booted device ligner ikke en 13\" iPad eller iPhone Pro Max."
    echo "          App Store kræver 2752x2064 (iPad Pro 13\") eller 2796x1290 (iPhone 15 Pro Max)."
    echo "          Tryk Enter for at fortsætte alligevel, eller Ctrl+C for at afbryde."
    read -r
fi

# --- Scene definitions -------------------------------------------------------

# Format: "filename|instruction"
SCENES=(
    "01-race|HERO-SHOT: Race i gang på Grand Prix-banen i overhead-kamera. Mindst 2 biler synlige, HUD med fart og omgange vises."
    "02-menu|BANEVÆLGER: Åbn hovedmenuen, så bane-thumbnails (Begynder Oval, Otte-tal, Grand Prix, Lauras Løkke) er synlige."
    "03-multiplayer|MULTIPLAYER: Start et 4-spiller race (eller AI fyld op til 4). Vis flere biler i en kurve samtidig."
    "04-ar-mode|AR-MODE: Skift til AR (kamera-knap), peg på et bord eller gulv — banen spawner synligt i scenen med en bil på."
    "05-countdown|COUNTDOWN/START: Fang 3-2-1-GO countdown lige før race-start. Biler i grid-position, klar til at køre."
    "06-result|RESULTAT: Race afsluttet, resultat-skærm med vinder og tider vises."
)

# --- Capture loop ------------------------------------------------------------

TOTAL=${#SCENES[@]}
INDEX=0

echo ""
echo "Klar til at fange $TOTAL skud → $OUT_DIR"
echo "----------------------------------------------------------------------"

for ENTRY in "${SCENES[@]}"; do
    INDEX=$((INDEX + 1))
    NAME="${ENTRY%%|*}"
    INSTRUCTION="${ENTRY#*|}"
    OUT_FILE="$OUT_DIR/$NAME.png"

    echo ""
    echo "[$INDEX/$TOTAL] $NAME"
    echo "          $INSTRUCTION"
    echo "          Naviger i Simulatoren, og tryk Enter når du er klar (s = skip)."
    read -r REPLY

    if [[ "$REPLY" == "s" || "$REPLY" == "S" ]]; then
        echo "          → sprunget over"
        continue
    fi

    if xcrun simctl io booted screenshot --mask=ignored "$OUT_FILE" 2>/dev/null; then
        if command -v sips >/dev/null 2>&1; then
            W="$(sips -g pixelWidth "$OUT_FILE" | awk '/pixelWidth/ {print $2}')"
            H="$(sips -g pixelHeight "$OUT_FILE" | awk '/pixelHeight/ {print $2}')"
            if [[ "$W" -lt "$H" ]]; then
                echo "          ADVARSEL: Billede er portrait (${W}x${H})."
                echo "          Roter Simulator med ⌘+→ og tryk Enter for at tage skuddet igen (s = behold portrait)."
                read -r RETRY
                if [[ "$RETRY" != "s" && "$RETRY" != "S" ]]; then
                    xcrun simctl io booted screenshot --mask=ignored "$OUT_FILE" 2>/dev/null || true
                    W="$(sips -g pixelWidth "$OUT_FILE" | awk '/pixelWidth/ {print $2}')"
                    H="$(sips -g pixelHeight "$OUT_FILE" | awk '/pixelHeight/ {print $2}')"
                fi
            fi
            echo "          → gemt (${W}x${H}) → $OUT_FILE"
        else
            echo "          → gemt → $OUT_FILE"
        fi
    else
        echo "          FEJL ved screenshot — springer videre"
    fi
done

echo ""
echo "----------------------------------------------------------------------"
echo "Færdig. Filer i: $OUT_DIR"
ls -lh "$OUT_DIR" 2>/dev/null || true
