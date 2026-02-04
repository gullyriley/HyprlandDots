#!/usr/bin/env bash

# --- settings ---
INTERVAL=0.08
TOP_PEEK=2          # px from top to reveal
BAR_HEIGHT=42       # your waybar height (your log showed 42)
LOG="$HOME/.cache/waybar-autohide.log"

mkdir -p "$HOME/.cache"
: > "$LOG"

log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" >> "$LOG"; }

# Wait for waybar to exist (prevents startup race)
for i in {1..40}; do
  pgrep -x waybar >/dev/null 2>&1 && break
  sleep 0.05
done

if ! pgrep -x waybar >/dev/null 2>&1; then
  log "ERROR: waybar not running; exiting"
  exit 0
fi

visible=1
log "autohide started (visible=$visible)"

clients_on_active_ws() {
  local ws count
  ws="$(hyprctl -j activeworkspace 2>/dev/null | jq -r '.id' 2>/dev/null)"
  [[ "$ws" =~ ^[0-9]+$ ]] || { echo 0; return; }

  count="$(hyprctl -j clients 2>/dev/null \
    | jq "[.[] | select(.mapped==true and .workspace.id==${ws})] | length" 2>/dev/null)"
  [[ "$count" =~ ^[0-9]+$ ]] || count=0
  echo "$count"
}

cursor_y() {
  local y
  y="$(hyprctl cursorpos 2>/dev/null | awk -F',' '{gsub(/[[:space:]]/,"",$2); print $2}')"
  [[ "$y" =~ ^[0-9]+$ ]] || y=99999
  echo "$y"
}

toggle_waybar() {
  # SIGUSR1 is toggle in your setup (it worked earlier)
  pkill -SIGUSR1 waybar >/dev/null 2>&1 || true
}

while true; do
  windows="$(clients_on_active_ws)"
  y="$(cursor_y)"

  if [[ "$windows" -eq 0 ]]; then
    # No windows -> always visible
    if [[ "$visible" -eq 0 ]]; then
      log "show (no windows)"
      toggle_waybar
      visible=1
    fi
  else
    if [[ "$visible" -eq 0 ]]; then
      # Hidden -> reveal only when mouse hits top edge
      if [[ "$y" -le "$TOP_PEEK" ]]; then
        log "show (peek) y=$y"
        toggle_waybar
        visible=1
      fi
    else
      # Visible -> keep visible while mouse is within bar area
      if [[ "$y" -gt "$BAR_HEIGHT" ]]; then
        log "hide (leave bar) y=$y"
        toggle_waybar
        visible=0
      fi
    fi
  fi

  sleep "$INTERVAL"
done
