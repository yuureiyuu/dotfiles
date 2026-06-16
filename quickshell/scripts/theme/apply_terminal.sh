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

python3 "$script_dir/render_targets.py" --terminal-only >/dev/null

if pgrep -x foot >/dev/null 2>&1; then
    pkill -SIGUSR1 -x foot >/dev/null 2>&1 || true
fi

if pgrep -x footclient >/dev/null 2>&1; then
    pkill -SIGUSR1 -x footclient >/dev/null 2>&1 || true
fi

terminal_sequences_file="${XDG_CACHE_HOME:-$HOME/.cache}/wal/sequences"
if [ ! -f "$terminal_sequences_file" ]; then
    terminal_sequences_file="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/generated/terminal/sequences.txt"
fi

if [ -f "$terminal_sequences_file" ]; then
    for tty in /dev/pts/[0-9]*; do
        [ -w "$tty" ] || continue
        {
            cat "$terminal_sequences_file" > "$tty" 2>/dev/null || true
        } & disown || true
    done
fi
