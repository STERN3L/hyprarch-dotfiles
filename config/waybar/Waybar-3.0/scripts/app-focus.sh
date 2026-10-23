#!/usr/bin/env bash
# Focus the application's window if one exists, otherwise (re)launch it.
# Usage: app-focus.sh <window class regex> <launch command...>

class=$1
shift

if hyprctl clients -j | jq -e --arg c "^($class)$" 'any(.[]; .class | test($c))' >/dev/null; then
  hyprctl dispatch focuswindow "class:^($class)$" >/dev/null
else
  setsid -f "$@" >/dev/null 2>&1
fi
