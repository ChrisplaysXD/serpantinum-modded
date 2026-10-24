#!/usr/bin/env bash
# Set Hyprland vibrance screen shader strength via hyprshade
# Usage: vibrance.sh [0.0-1.0]   (e.g. 0.65; 0 = unchanged colors)

V="${1:-0.65}"
V=$(python3 -c "import sys; print(round(float(sys.argv[1]), 3))" "$V" 2>/dev/null) || V="0.65"

SRC="/usr/share/hyprshade/shaders/vibrance.glsl"
DST="${HOME}/.config/hypr/shaders/vibrance.glsl"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/serpantinum"

mkdir -p "$(dirname "$DST")" "$STATE_DIR"
if [ ! -f "$DST" ] && [ -f "$SRC" ]; then
    cp "$SRC" "$DST"
fi

if [ -f "$DST" ]; then
    sed -i "s/^const float VIB_VIBRANCE = .*/const float VIB_VIBRANCE = ${V};/" "$DST"
else
    echo "vibrance.glsl not found in $DST or $SRC" >&2
    exit 1
fi

echo "$V" > "$STATE_DIR/vibrance"

if command -v hyprshade >/dev/null 2>&1; then
    hyprshade on vibrance
fi
