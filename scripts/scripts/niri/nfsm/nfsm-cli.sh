#!/bin/bash
SOCKET="${NFSM_SOCKET:-/run/user/1000/nfsm.sock}"
trap 'notify-send --icon="$(pwd)/icon.png" --app-name="NSFM" "Niri FullScreen Manager" "Failed to connect to NFSM_SOCKET: $SOCKET" && niri msg action fullscreen-window' ERR
echo 'FullscreenRequest' | socat - UNIX-CONNECT:"$SOCKET"

