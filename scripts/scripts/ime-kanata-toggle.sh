#!/bin/bash
STATE=$(fcitx5-remote -n)

if [ "$STATE" = "keyboard-us" ]; then
    # Currently English, switch to Korean + qwerty
    fcitx5-remote -g hangul
    echo '{"ChangeLayer":{"new":"qwerty"}}' | nc localhost 5829
else
    # Currently Korean, switch to English + gallium
    fcitx5-remote -g Default
    echo '{"ChangeLayer":{"new":"gallium-v2"}}' | nc localhost 5829
fi
