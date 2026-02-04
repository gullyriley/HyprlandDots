#!/usr/bin/env bash
count="$(checkupdates 2>/dev/null | wc -l)"
state="$HOME/.cache/waybar-updates-last"

last="0"
[[ -f "$state" ]] && last="$(cat "$state")"

# notify only when it transitions from 0 -> >0 or the number changes
if [[ "$count" -gt 0 && "$count" != "$last" ]]; then
  notify-send "Updates available" "($count) updates"
fi

echo "$count" > "$state"
echo "$count"
