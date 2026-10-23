#!/usr/bin/env bash
# Icon for an application that is running (even with no open window), as Waybar JSON.
# Usage: app-status.sh <process name> <window class regex> <display name> <icon>
# Prints an empty text (module hidden) when the application is not running.

proc=$1 class=$2 name=$3 icon=$4

if ! pgrep -x "$proc" >/dev/null; then
  echo '{"text": ""}'
  exit 0
fi

ws=$(hyprctl clients -j | jq -r --arg c "^($class)$" \
  '[.[] | select(.class | test($c)) | .workspace.name] | unique | join(", ")')

if [ -n "$ws" ]; then
  tooltip="$name — window on workspace $ws\nClick: go to window"
  cls=windowed
else
  tooltip="$name — running in the background\nClick: open"
  cls=background
fi

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$icon" "$tooltip" "$cls"
