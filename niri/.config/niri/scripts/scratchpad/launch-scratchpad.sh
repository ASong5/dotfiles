#!/usr/bin/env bash

selected=$(/home/pundrew/.config/rofi/niri-scratchpad-rofi.sh | rofi -show-icons -dmenu -i -p Scratchpad 2>/dev/null)

if [[ -n "$selected" ]]; then
    # Extract window ID (everything before the first |)
    window_id="${selected%%:*}"
    niri msg action focus-monitor DP-1
    /home/pundrew/.config/niri/scripts/scratchpad/niri-scratchpad.py --multi-monitor --window-id "$window_id"
fi
