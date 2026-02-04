#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
STATE_FILE="$HOME/.cache/current_wallpaper"

mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f | sort)

[ ${#WALLPAPERS[@]} -eq 0 ] && exit 1

CURRENT=0
if [[ -f "$STATE_FILE" ]]; then
    CURRENT=$(cat "$STATE_FILE")
fi

NEXT=$(( (CURRENT + 1) % ${#WALLPAPERS[@]} ))

echo "$NEXT" > "$STATE_FILE"

swww img "${WALLPAPERS[$NEXT]}" \
  --transition-type wipe \
  --transition-duration 0.6 \
  --transition-fps 60
