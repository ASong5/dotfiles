source "$HOME/.bashrc"
export SDL_VIDEODRIVER=wayland,x11,windows
export TERM=screen-256color
export MOZ_ENABLE_WAYLAND=1
XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/flatpak/app"
XMODIFIERS=@im=fcitx
