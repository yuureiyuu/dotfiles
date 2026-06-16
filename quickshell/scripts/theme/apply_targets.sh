#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
state_root="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/theme"
mode_file="$state_root/mode"

mode="${1:-}"
if [ "$mode" != "dark" ] && [ "$mode" != "light" ]; then
    if [ -f "$mode_file" ]; then
        mode="$(tr -d '[:space:]' < "$mode_file")"
    fi
fi
if [ "$mode" != "dark" ] && [ "$mode" != "light" ]; then
    mode="dark"
fi

mkdir -p "$state_root"
printf '%s\n' "$mode" > "$mode_file"

"$script_dir/apply_terminal.sh" "$mode" >/dev/null
python3 "$script_dir/apply_hyprland.py" "$mode" >/dev/null || true

export QT_QPA_PLATFORMTHEME=kde
export QT_STYLE_OVERRIDE=kvantum
export KDE_SESSION_VERSION=6
export XDG_CURRENT_DESKTOP=KDE:Hyprland

python3 "$script_dir/render_targets.py" --desktop-only >/dev/null

theme_name="AjisaiShell"

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user import-environment \
        QT_QPA_PLATFORMTHEME \
        QT_STYLE_OVERRIDE \
        KDE_SESSION_VERSION \
        XDG_CURRENT_DESKTOP >/dev/null 2>&1 || true
fi

if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    plasma-apply-colorscheme "$theme_name" >/dev/null 2>&1 || true
fi

if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme "$theme_name" >/dev/null 2>&1 || true
    kwriteconfig6 --file kdeglobals --group UiSettings --key ColorScheme "$theme_name" >/dev/null 2>&1 || true
elif command -v kwriteconfig5 >/dev/null 2>&1; then
    kwriteconfig5 --file kdeglobals --group General --key ColorScheme "$theme_name" >/dev/null 2>&1 || true
    kwriteconfig5 --file kdeglobals --group UiSettings --key ColorScheme "$theme_name" >/dev/null 2>&1 || true
fi

if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.KGlobalSettings /KGlobalSettings notifyChange int:0 int:0 >/dev/null 2>&1 || true
elif command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.KGlobalSettings /KGlobalSettings notifyChange int:0 int:0 >/dev/null 2>&1 || true
fi

find "${XDG_CACHE_HOME:-$HOME/.cache}" -maxdepth 1 \
    \( -name "icon-cache.kcache" -o -name "ksycoca*" -o -name "plasma_theme_*.kcache" \) \
    -type f -delete >/dev/null 2>&1 || true

kbuildsycoca_bin=""
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca_bin="$(command -v kbuildsycoca6)"
elif command -v kbuildsycoca5 >/dev/null 2>&1; then
    kbuildsycoca_bin="$(command -v kbuildsycoca5)"
else
    for candidate in \
        "$HOME/.nix-profile/bin/kbuildsycoca6" \
        "$HOME/.local/state/nix/profile/bin/kbuildsycoca6" \
        "/etc/profiles/per-user/$USER/bin/kbuildsycoca6" \
        "/run/current-system/sw/bin/kbuildsycoca6" \
        "$HOME/.nix-profile/bin/kbuildsycoca5" \
        "$HOME/.local/state/nix/profile/bin/kbuildsycoca5" \
        "/etc/profiles/per-user/$USER/bin/kbuildsycoca5" \
        "/run/current-system/sw/bin/kbuildsycoca5"; do
        if [ -x "$candidate" ]; then
            kbuildsycoca_bin="$candidate"
            break
        fi
    done
fi

if [ -n "$kbuildsycoca_bin" ]; then
    "$kbuildsycoca_bin" --noincremental >/dev/null 2>&1 || true
fi

if pgrep -f xdg-desktop-portal-kde >/dev/null 2>&1; then
    pkill -f xdg-desktop-portal-kde >/dev/null 2>&1 || true
fi
