#!/bin/bash
MAC="E4:58:BC:C3:D0:4E"
MAX_RETRIES=5
SLEEP_SEC=4        # Wait after connect for negotiation
CODEC_WAIT=1       # Wait after set_profile for PipeWire to negotiate codec
RETRY_WAIT=2       # Wait after disconnect before retrying
TIMEOUT_SEC=12
TRIGGER="/home/pundrew/.dotfiles/scripts/scripts/bose/bose-notify"
ICON="audio-headphones"

LOCKFILE="/run/bose-connect.lock"

if ! mkdir "$LOCKFILE" 2>/dev/null; then
    exit 0
fi
trap "rmdir '$LOCKFILE'" EXIT

notify() {
    local urgency="normal"
    [[ "$2" == "-u critical" ]] && urgency="critical"
    echo "${urgency}|$1" >> "$TRIGGER"
}

check_codec() {
    sudo -u pundrew XDG_RUNTIME_DIR=/run/user/1000 pactl list cards 2>/dev/null | grep "Active Profile" | grep -q "a2dp-sink-sbc_xq"
}

set_profile() {
    sudo -u pundrew XDG_RUNTIME_DIR=/run/user/1000 pactl set-card-profile "bluez_card.E4_58_BC_C3_D0_4E" a2dp_sink_sbc_xq 2>/dev/null
}

try_connect() {
    for ((i = 1; i <= MAX_RETRIES; i++)); do
        notify "Attempt $i: Connecting..."
        timeout "$TIMEOUT_SEC" bluetoothctl connect "$MAC" >/dev/null 2>&1
        sleep "$SLEEP_SEC"
        if bluetoothctl info "$MAC" | grep -q "Connected: yes"; then
            set_profile
            sleep "$CODEC_WAIT"
            if check_codec; then
                notify "Connected with SBC-XQ on attempt $i."
                return 0
            else
                notify "Connected but SBC-XQ unavailable, retrying..." "-u critical"
                bluetoothctl disconnect "$MAC" >/dev/null 2>&1
                sleep "$RETRY_WAIT"
            fi
        else
            notify "Attempt $i failed. Retrying..." "-u critical"
        fi
    done
    notify "Failed after $MAX_RETRIES attempts — SBC-XQ unavailable. Connect manually." "-u critical"
    return 1
}

if bluetoothctl info "$MAC" | grep -q "Connected: yes"; then
    if [[ "$1" != "--quiet" ]]; then
        notify "Disconnecting Bose headphones..."
        bluetoothctl disconnect "$MAC" >/dev/null 2>&1
        notify "Bose headphones disconnected."
        exit 0
    fi
    notify "Already connected — verifying codec..."
    set_profile
    sleep "$CODEC_WAIT"
    if check_codec; then
        notify "SBC-XQ active."
    else
        notify "SBC-XQ unavailable, reconnecting..." "-u critical"
        bluetoothctl disconnect "$MAC" >/dev/null 2>&1
        sleep "$RETRY_WAIT"
        try_connect
    fi
    exit 0
fi

try_connect
