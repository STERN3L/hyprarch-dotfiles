#!/bin/bash

while true; do
    battery_level=$(cat /sys/class/power_supply/BAT0/capacity)
    if [[ $battery_level -lt 20 ]]; then
            notify-send "Battery low" "${battery_level}% left."
    fi
    sleep 120 
done

