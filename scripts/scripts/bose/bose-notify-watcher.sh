#!/bin/bash
TRIGGER="/home/pundrew/.dotfiles/scripts/scripts/bose/bose-notify"
ICON="/usr/share/icons/breeze/devices/64/audio-speakers.svg"

# Clean up any leftover trigger from last session
rm -f "$TRIGGER"
touch "$TRIGGER"
chmod 0666 "$TRIGGER"

tail -f "$TRIGGER" | while IFS='|' read -r urgency msg; do
    [[ -z "$msg" ]] && continue
    if [[ "$urgency" == "critical" ]]; then
        notify-send -u critical -i "$ICON" "Bose Connect" "$msg"
    else
        notify-send -i "$ICON" "Bose Connect" "$msg"
    fi
done
