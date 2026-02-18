#!/bin/bash
# Save as ~/check_bluetooth_state.sh

echo "=== Bluetooth Status ==="
bluetoothctl show

echo -e "\n=== Connected Devices ==="
bluetoothctl devices Connected

echo -e "\n=== Bose Device Info ==="
bluetoothctl info | grep -A 20 "Bose"

echo -e "\n=== PipeWire Sinks ==="
pactl list sinks short

echo -e "\n=== PipeWire Cards ==="
pactl list cards short

echo -e "\n=== Bluetooth systemd service ==="
systemctl status bluetooth --no-pager -l
