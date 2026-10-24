#!/usr/bin/env bash
# Apply display adjustments using available tools
# Usage: display_adjust.sh [saturation PERCENT] [contrast PERCENT]

SAT=100
CONTRAST=100

while [[ $# -gt 0 ]]; do
  case $1 in
    --saturation) SAT="$2"; shift 2 ;;
    --contrast) CONTRAST="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "Display settings -> saturation: ${SAT}%, contrast: ${CONTRAST}%"
# Note: wl-gammarelay-rs handles temperature/brightness; full saturation/contrast requires shader/compositor filter.
