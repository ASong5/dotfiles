#!/bin/bash

QWERTY_APP_IDS=(
)

QWERTY_TITLE_PATTERNS=("MapleRoyals")

switch_layer() {
    printf '{"ChangeLayer":{"new":"%s"}}\n' "$1" >/dev/tcp/localhost/5829 2>/dev/null || true
}

declare -A WINDOW_APP_IDS
declare -A WINDOW_TITLES

update_windows() {
    local json="$1"
    local ids
    ids=$(echo "$json" | jq --unbuffered -r '.[].id' 2>/dev/null || echo "")
    while read -r id; do
        [[ -z "$id" ]] && continue
        local app_id title
        app_id=$(echo "$json" | jq --unbuffered -r --argjson id "$id" '.[] | select(.id == $id) | .app_id // ""')
        title=$(echo "$json" | jq --unbuffered -r --argjson id "$id" '.[] | select(.id == $id) | .title // ""')
        WINDOW_APP_IDS[$id]="$app_id"
        WINDOW_TITLES[$id]="$title"
    done <<<"$ids"
}

handle_focus() {
    local id="$1"
    local app_id="${WINDOW_APP_IDS[$id]:-}"
    local title="${WINDOW_TITLES[$id]:-}"

    if [ -n "$app_id" ]; then
        for aid in "${QWERTY_APP_IDS[@]}"; do
            if [ "$app_id" = "$aid" ]; then
                switch_layer "qwerty"
                return
            fi
        done
        switch_layer "gallium-v2"
    else
        for pattern in "${QWERTY_TITLE_PATTERNS[@]}"; do
            if echo "$title" | grep -qE "$pattern"; then
                switch_layer "qwerty"
                return
            fi
        done
        switch_layer "gallium-v2"
    fi
}

# Initial sync (important!)
echo "niri-kanata-switcher: Initial window sync..." >&2
current=$(niri msg --json windows 2>/dev/null || echo '[]')
update_windows "$current"

# Reconnection loop
while true; do
    echo "niri-kanata-switcher: Starting event stream at $(date)..." >&2

    stdbuf -oL niri msg --json event-stream 2>/dev/null | while read -r line; do
        event=$(echo "$line" | jq --unbuffered -r 'keys[0] // empty' 2>/dev/null || echo "")

        case "$event" in
        WindowFocusChanged)
            id=$(echo "$line" | jq --unbuffered -r '.WindowFocusChanged.id' 2>/dev/null)
            [[ -n "$id" ]] && handle_focus "$id"
            ;;
        WindowsChanged)
            update_windows "$(echo "$line" | jq --unbuffered -r '.WindowsChanged.windows' 2>/dev/null || echo '[]')"
            ;;
        WindowOpenedOrChanged)
            update_window() { # inline minimal version
                local json="$1"
                local id app_id title
                id=$(echo "$json" | jq --unbuffered -r '.id' 2>/dev/null)
                app_id=$(echo "$json" | jq --unbuffered -r '.app_id // ""')
                title=$(echo "$json" | jq --unbuffered -r '.title // ""')
                WINDOW_APP_IDS[$id]="$app_id"
                WINDOW_TITLES[$id]="$title"
            }
            update_window "$(echo "$line" | jq --unbuffered -r '.WindowOpenedOrChanged.window' 2>/dev/null || echo '{}')"
            ;;
        esac
    done

    echo "niri-kanata-switcher: Event stream ended (likely suspend). Reconnecting in 3s..." >&2
    sleep 3
done
