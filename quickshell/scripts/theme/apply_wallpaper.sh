#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: apply_wallpaper.sh IMAGE_PATH" >&2
    exit 1
fi

image_path="$1"
state_root="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/theme"
wallpaper_state_file="$state_root/current-wallpaper"

mkdir -p "$state_root"

if command -v awww >/dev/null 2>&1 && command -v awww-daemon >/dev/null 2>&1; then
    if ! awww query >/dev/null 2>&1; then
        awww-daemon --format xrgb >/dev/null 2>&1 &
        sleep 0.3
    fi

    awww img "$image_path" \
        --transition-type wipe \
        --transition-angle 30 \
        --transition-step 90 \
        --transition-fps 60
else
    echo "No supported wallpaper backend found (need awww and awww-daemon)." >&2
    exit 1
fi

printf '%s\n' "$image_path" > "$wallpaper_state_file"
