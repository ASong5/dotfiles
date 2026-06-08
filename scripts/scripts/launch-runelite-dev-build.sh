#!/bin/bash
set -x

REPO=/home/pundrew/git/runelite-fork/runelite
ICON=/home/pundrew/.local/share/icons/runelite.png
LOG_FILE=/tmp/runelite-build-progress.log

# Add or remove feature branches here to control what goes into daily-driver
FEATURE_BRANCHES=(
    feature/fix-anchors-to-chatbox
)

notify_fail() {
    local msg="$1"
    echo "ERROR: $msg" >&2
    notify-send -a runelite-build-progress -i "$ICON" "RuneLite launch failed" "$msg"
}

cd "$REPO" || { notify_fail "Could not cd to repo at $REPO"; exit 1; }

# Update master to latest upstream
if ! git checkout master 2>&1; then
    notify_fail "git checkout master failed — dirty index or conflict. Fix manually."
    exit 1
fi

git fetch upstream master

UPSTREAM_CHANGES=$(git rev-list --count HEAD..upstream/master)

if [ "$UPSTREAM_CHANGES" -ne 0 ]; then
    > "$LOG_FILE"
    notify-send -a runelite-build-progress -i "$ICON" "Upstream changes detected" \
        "Fetching changes and rebuilding. Click to view progress"

    if ! git reset --hard upstream/master >> "$LOG_FILE" 2>&1; then
        notify_fail "Failed to update master to upstream. Fix manually."
        exit 1
    fi

    # Rebase each feature branch onto updated master
    for branch in "${FEATURE_BRANCHES[@]}"; do
        if ! git checkout "$branch" 2>&1; then
            notify_fail "git checkout $branch failed. Fix manually."
            exit 1
        fi

        if ! git rebase master >> "$LOG_FILE" 2>&1; then
            notify_fail "git rebase failed on $branch — running git rebase --abort. Fix conflicts manually."
            git rebase --abort
            exit 1
        fi
    done

    # Rebuild daily-driver from master + all feature branches
    if ! git checkout master 2>&1; then
        notify_fail "git checkout master failed after rebase. Fix manually."
        exit 1
    fi

    git branch -D daily-driver
    git checkout -b daily-driver

    for branch in "${FEATURE_BRANCHES[@]}"; do
        if ! git merge "$branch" --no-ff -m "daily-driver: merge $branch" >> "$LOG_FILE" 2>&1; then
            notify_fail "Failed to merge $branch into daily-driver. Fix manually."
            exit 1
        fi
    done

    if ! ./gradlew clean >> "$LOG_FILE" 2>&1; then
        notify_fail "gradlew clean failed. Check $LOG_FILE for details."
        exit 1
    fi

    if ! ./gradlew :client:shadowJar --refresh-dependencies -x test >> "$LOG_FILE" 2>&1; then
        notify_fail "gradlew shadowJar failed. Check $LOG_FILE for details."
        exit 1
    fi
else
    # No upstream changes, just make sure we're on daily-driver
    if ! git checkout daily-driver 2>&1; then
        notify_fail "git checkout daily-driver failed. Fix manually."
        exit 1
    fi
fi

LIBS_DIR="$REPO/runelite-client/build/libs"
JAR=$(ls "$LIBS_DIR"/client-*-SNAPSHOT-shaded.jar 2>/dev/null | head -n1)

if [ -z "$JAR" ]; then
    notify_fail "No shaded jar found at $LIBS_DIR — build may not have run yet."
    exit 1
fi

PLUGINHUB_VERSION=$(git fetch --tags upstream master | git -C "$REPO" tag -l | \
                    grep -v 'internal' | sort -rV | head -n1 | sed -r -e 's/.*-(.+)/\1/')

cd "$LIBS_DIR"

XRE_PROFILE_PATH=/home/pundrew/.mozilla/firefox/x15bub2p.default-release-1 \
exec java -Drunelite.pluginhub.version="$PLUGINHUB_VERSION" \
    --add-opens=java.desktop/sun.awt=ALL-UNNAMED \
    -jar "$JAR" "$@" &

ALREADY_OPEN=$(niri msg --json windows | jq -e '.[] | select(.app_id == "net-runelite-client-RuneLite")' > /dev/null 2>&1 && echo "true" || echo "false")

if [ "$ALREADY_OPEN" = "false" ]; then
    while true; do
        RL_ID=$(niri msg --json windows | jq '.[] | select(.app_id == "net-runelite-client-RuneLite" and .title != "RuneLite Launcher") | .id' | head -n1)
        if [ -n "$RL_ID" ]; then
            niri msg action set-dynamic-cast-window --id "$RL_ID"
            break
        fi
        sleep 0.5
    done
fi
