#!/bin/bash
set -x
cd /home/pundrew/git/runelite-fork/runelite
git checkout master
git fetch upstream master
# Comment out to pause pulling upstream changes (e.g. upstream breaks a plugin or client feature you rely on).
# Uncomment to resume when the issue is resolved.
#
if [ "$(git rev-list --count HEAD..upstream/master)" -ne 0 ]; then
    LOG_FILE="/tmp/runelite-build-progress.log"
    > "$LOG_FILE"  # Clear previous log
    notify-send -a runelite-build-progress -i /home/pundrew/.local/share/icons/runelite.png "Upstream changes detected" \
        "Fetching changes and rebuilding. Click to view progress"
    (
        git rebase upstream/master 
        ./gradlew clean
        ./gradlew :client:shadowJar --refresh-dependencies
    ) > >(tee -a "$LOG_FILE") 2>&1
fi
PLUGINHUB_VERSION=$(git fetch --tags upstream master | git -C "$HOME/git/runelite-fork/runelite" tag -l | \
                    grep -v 'internal' | sort -rV | head -n1 | sed -r -e 's/.*-(.+)/\1/')
cd ~/git/runelite-fork/runelite/runelite-client/build/libs
 XRE_PROFILE_PATH=/home/pundrew/.mozilla/firefox/x15bub2p.default-release-1 \
exec java -Drunelite.pluginhub.version="$PLUGINHUB_VERSION" \
    --add-opens=java.desktop/sun.awt=ALL-UNNAMED \
    -jar "$(ls client-*-SNAPSHOT-shaded.jar | head -n1)" "$@" &

 # Check if RuneLite was already open before this launch
ALREADY_OPEN=$(niri msg --json windows | jq -e '.[] | select(.app_id == "net-runelite-client-RuneLite")' > /dev/null 2>&1 && echo "true" || echo "false")

# Wait for RuneLite window to appear then set dynamic cast
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
