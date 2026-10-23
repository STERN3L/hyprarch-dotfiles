#!/usr/bin/env bash
# Low-battery notification, run every 2 minutes by battery-notify.timer (systemd --user).
# Notifies once per threshold; the state is reset when the charger is plugged back in.

capacity=$(cat /sys/class/power_supply/BAT0/capacity)
status=$(cat /sys/class/power_supply/BAT0/status)
state="${XDG_RUNTIME_DIR:-/tmp}/battery-notify.last"

if [ "$status" != "Discharging" ]; then
  rm -f "$state"
  exit 0
fi

last=$(cat "$state" 2>/dev/null || echo 100)

if [ "$capacity" -le 10 ] && [ "$last" -gt 10 ]; then
  notify-send -u critical -i battery-caution "Battery critical" "${capacity}% left — plug in the charger."
  echo 10 >"$state"
elif [ "$capacity" -le 20 ] && [ "$last" -gt 20 ]; then
  notify-send -u normal -i battery-low "Battery low" "${capacity}% left."
  echo 20 >"$state"
fi
