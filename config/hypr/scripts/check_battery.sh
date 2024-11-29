#!/bin/bash

while true; do
    battery_level=$(/usr/bin/cat /sys/class/power_supply/BAT0/capacity)
    is_charging=$(/usr/bin/cat /sys/class/power_supply/BAT0/status)
    if [[ $battery_level -lt 20 && $is_charging == "Discharging" ]]; then
            notify-send "Battery low" "${battery_level}% left."
    fi
    sleep 60 
done

