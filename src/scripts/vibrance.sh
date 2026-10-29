#!/usr/bin/env bash
# Set Hyprland vibrance + gamma screen shader
# Usage: vibrance.sh [vibrance 0.0-1.0] [gamma 0.5-2.0]
V="${1:-0.65}"
G="${2:-1.0}"
V=$(python3 -c "import sys; print(round(float(sys.argv[1]), 3))" "$V" 2>/dev/null) || V="0.65"
G=$(python3 -c "import sys; print(round(float(sys.argv[1]), 3))" "$G" 2>/dev/null) || G="1.0"

SRC="/usr/share/hyprshade/shaders/vibrance.glsl"
DST="${HOME}/.config/hypr/shaders/vibrance.glsl"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/serpantinum"

mkdir -p "$(dirname "$DST")" "$STATE_DIR"
if [ ! -f "$DST" ] && [ -f "$SRC" ]; then
    cp "$SRC" "$DST"
fi

if [ -f "$DST" ]; then
    sed -i "s/^const float VIB_VIBRANCE = .*/const float VIB_VIBRANCE = ${V};/" "$DST"
    sed -i "s/^const float GAMMA = .*/const float GAMMA = ${G};/" "$DST"
else
    echo "vibrance.glsl not found in $DST or $SRC" >&2
    exit 1
fi

echo "$V" > "$STATE_DIR/vibrance"

if command -v hyprshade >/dev/null 2>&1; then
    hyprshade on vibrance
fi
