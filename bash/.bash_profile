source "$HOME/.bashrc"
# GTK_THEME=Adwaita:dark
export SDL_VIDEODRIVER=wayland,x11,windows
export _JAVA_AWT_WM_NONREPARENTING=1
# export TERM=screen-256color
export MOZ_ENABLE_WAYLAND=1
export XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/flatpak/app"
export XMODIFIERS=@im=fcitx
. "$HOME/.cargo/env"

# Created by `pipx` on 2025-10-02 13:00:40
export PATH="$PATH:/home/pundrew/.local/bin"
