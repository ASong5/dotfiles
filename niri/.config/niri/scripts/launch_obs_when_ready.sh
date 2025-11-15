#!/usr/bin/env bash

WINDOW1="Floating Window - Show Me The Key"
WINDOW2="RuneLite"

while true; do
    current_windows=$(niri msg windows | grep "Title:" | sed 's/Title: //')
    
    win1_seen=false
    win2_seen=false

    if echo "$current_windows" | grep -iq "$WINDOW1"; then
        win1_seen=true
        echo "Detected: $WINDOW1"
    fi
    if echo "$current_windows" | grep -iq "$WINDOW2"; then
        win2_seen=true
        echo "Detected: $WINDOW2"
    fi

    if $win1_seen && $win2_seen; then
        echo "Both windows detected! Launching OBS..."
        flatpak run com.obsproject.Studio --startreplaybuffer --disable-shutdown-check &
        exit 0
    fi

    sleep 1  # wait 1 second before checking again
done

