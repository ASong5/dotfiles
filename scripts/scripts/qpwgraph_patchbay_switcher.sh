#!/bin/bash

# BT_MAC="AC:80:FB:A8:07:64"
BT_SINK="bluez_output.AC_80_FB_A8_07_64.1"
# Find sink name matching 'alsa_output.pci-0000_0b_00.*.analog-stereo'
REG_SINK=$(pactl list short sinks | grep -E 'alsa_output.pci-0000_0b_00\.[0-9]+\.analog-stereo' | awk '{print $2}')

echo "Detected regular sink: $REG_SINK"

# STARSHIP_NODE="alsa_output.pci-0000_0b_00.4.analog-stereo"

CURRENT_STATE="UNKNOWN"

while true; do
  if pactl list short sinks | grep -q "$BT_SINK"; then
    NEW_STATE="BT"
  else
    NEW_STATE="REG"
  fi

  if [[ "$NEW_STATE" != "$CURRENT_STATE" ]]; then
    echo "Switching to $NEW_STATE"

    if [[ "$NEW_STATE" == "BT" ]]; then
      NEW_STATE="BT" 
      echo "→ Setting Galaxy Buds as default sink"
      pactl set-default-sink "$BT_SINK"

      echo "→ Waiting briefly before suspending regular sink"
      sleep 1  # Add a 1-second pause

      echo "→ Disconnecting Starship outputs"
      pactl suspend-sink "$REG_SINK" true

    else
      echo "→ Setting Starship as default sink"
      NEW_STATE="REG"
      pactl set-default-sink "$REG_SINK"
      # pactl suspend-sink "$REG_SINK" false
    fi

    CURRENT_STATE="$NEW_STATE"
  fi

  sleep 3
done

