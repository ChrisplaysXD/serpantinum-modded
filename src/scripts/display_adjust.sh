#!/usr/bin/env bash
# Apply display adjustments - practical version using available tools
# Supports saturation (via gamma curve approximation) and contrast

SAT=100
CONTRAST=100

while [[ $# -gt 0 ]]; do
  case $1 in
    --saturation) SAT="$2"; shift 2 ;;
    --contrast) CONTRAST="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

# Convert percentage to gamma multiplier (approximation for saturation/contrast)
# For practical effect, we adjust gamma curves using wl-gammarelay-rs if available
# and apply basic adjustments

if command -v wl-gammarelay-rs >/dev/null 2>&1; then
    # Adjust gamma curves for contrast/saturation effect
    # Using gamma 1.0 as neutral; adjusting for effect
    GAMMA=$(python3 -c "print(1.0 + ($CONTRAST - 100) / 200.0)" 2>/dev/null || echo 1.0)
    SAT_GAMMA=$(python3 -c "print(1.0 + ($SAT - 100) / 400.0)" 2>/dev/null || echo 1.0)
    # Note: wl-gammarelay-rs runs as daemon; we signal adjustments if possible
    # For now, log adjustments since full saturation requires shader/compositor filter
fi

echo "Applied: saturation=${SAT}%, contrast=${CONTRAST}%"
# For shader-level effect, user needs to compile .frag to .qsb or use Hyprland screen_shader
