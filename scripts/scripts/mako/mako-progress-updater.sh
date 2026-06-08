#!/bin/bash

NOTIF_ID="$1"
[ -z "$NOTIF_ID" ] && exit 0

LOCK_FILE="/tmp/mako-progress-$NOTIF_ID.lock"

exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

get_notif_data() {
    makoctl list 2>/dev/null | awk -v id="$NOTIF_ID" '
        $0 ~ "^Notification "id":" {found=1; print; next}
        found && /^Notification / {exit}
        found {print}
    '
}

extract_field() {
    grep -m1 "^  $1:" | sed "s/^  $1: //"
}

notif_exists() {
    makoctl list 2>/dev/null | grep -q "^Notification $NOTIF_ID:"
}

NOTIF_DATA=$(get_notif_data)
[ -z "$NOTIF_DATA" ] && exit 0

SUMMARY=$(echo "$NOTIF_DATA" | head -n 1 | sed "s/^Notification $NOTIF_ID: //")
APP_NAME=$(echo "$NOTIF_DATA" | extract_field "App name" | tr -d ' ')
BODY=$(echo "$NOTIF_DATA" | extract_field "Body")
ICON=$(echo "$NOTIF_DATA" | extract_field "Icon")
ORIGINAL_ICON="$ICON"

if [[ -n "$ICON" && -f "$ICON" ]]; then
    COMPRESSED_ICON="/tmp/mako-icon-${NOTIF_ID}-shrink.png"
    convert "$ICON" -resize 64x64 -strip -quality 40 -define png:compression-level=9 "$COMPRESSED_ICON" 2>/dev/null
    ICON="$COMPRESSED_ICON"
fi

[ -z "$APP_NAME" ] && APP_NAME="notify-send"

DURATION=3
FPS=165
INTERVAL_MS=$((1000 / FPS))
NUM_STEPS=$((DURATION * FPS))

start_time=$(date +%s%3N)

(
    for ((i = 0; i < NUM_STEPS; i++)); do
        sleep "$(bc <<<"scale=3; $INTERVAL_MS/1000")"

        if ! notif_exists; then
            break
        fi

        now=$(date +%s%3N)
        elapsed=$((now - start_time))
        PROGRESS=$((100 - elapsed * 100 / (DURATION * 1000)))
        [ "$PROGRESS" -lt 0 ] && PROGRESS=0

        CURRENT_DATA=$(get_notif_data)
        CURRENT_SUMMARY=$(echo "$CURRENT_DATA" | head -n 1 | sed "s/^Notification $NOTIF_ID: //")
        CURRENT_BODY=$(echo "$CURRENT_DATA" | extract_field "Body")
        CURRENT_ICON=$(echo "$CURRENT_DATA" | extract_field "Icon")

        if [[ "$CURRENT_SUMMARY" != "$SUMMARY" || "$CURRENT_BODY" != "$BODY" || "$CURRENT_ICON" != "$ORIGINAL_ICON" ]]; then
            SUMMARY="$CURRENT_SUMMARY"
            BODY="$CURRENT_BODY"
            ORIGINAL_ICON="$CURRENT_ICON"
            ICON="$CURRENT_ICON"

            if [[ -n "$ICON" && -f "$ICON" ]]; then
                COMPRESSED_ICON="/tmp/mako-icon-${NOTIF_ID}-shrink.png"
                convert "$ICON" -resize 64x64 -strip -quality 40 -define png:compression-level=9 "$COMPRESSED_ICON" 2>/dev/null
                ICON="$COMPRESSED_ICON"
            fi

            start_time=$(date +%s%3N)
        fi

        if [ -n "$BODY" ]; then
            notify-send -r "$NOTIF_ID" -h int:value:"$PROGRESS" -a "$APP_NAME" -i "$ICON" "$SUMMARY" "$BODY" 2>/dev/null
        else
            notify-send -r "$NOTIF_ID" -h int:value:"$PROGRESS" -a "$APP_NAME" -i "$ICON" "$SUMMARY" 2>/dev/null
        fi
        if ((PROGRESS == 0)); then
            makoctl dismiss -n "$NOTIF_ID" 2>/dev/null
            break
        fi
    done

    if notif_exists; then
        makoctl dismiss -n "$NOTIF_ID" 2>/dev/null
    fi

    rm -f /tmp/mako-icon-"$NOTIF_ID"*
    rm -f "$LOCK_FILE"
) &

exit 0
