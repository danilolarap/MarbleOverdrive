#!/bin/sh
# Source-project launcher for Linux and macOS; no downloads or external assets.
set -eu
project_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
game_engine=${GODOT_BIN:-}
if [ -z "$game_engine" ]; then
    if command -v godot >/dev/null 2>&1; then
        game_engine=$(command -v godot)
    elif command -v godot4 >/dev/null 2>&1; then
        game_engine=$(command -v godot4)
    elif [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
        game_engine=/Applications/Godot.app/Contents/MacOS/Godot
    else
        printf '%s\n' 'Install Godot 4.4.1 or set GODOT_BIN to its executable.' >&2
        exit 1
    fi
fi
exec "$game_engine" --path "$project_dir" "$@"
