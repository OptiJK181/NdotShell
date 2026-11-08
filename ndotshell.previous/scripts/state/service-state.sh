#!/bin/sh

# Helper for NdotShell's newer services (Pomodoro stats, Clipboard history,
# Dynamic wallpaper config): reads and writes small JSON files.
#
#   service-state.sh save <name> <json>   write <json> to <name>.json
#   service-state.sh load  <name>         print the remembered JSON (or nothing)
#
# Files live in ${XDG_STATE_HOME:-~/.local/state}/ndotshell/ (runtime state,
# safe to wipe) — except clipboard history, which is user content: it goes to
# ${XDG_CONFIG_HOME:-~/.config}/ndotshell/ so it is backed up with the rest.
#
# Written to a temp file and moved into place, so a crash mid-save can't leave
# half a file.

mode="$1"
name="$2"

# Names are used as file names: only allow [a-z-].
case "$name" in
    *[!a-z-]*) exit 2 ;;
esac
[ -n "$name" ] || exit 2

case "$name" in
    clipboard-history)
        dir="${XDG_CONFIG_HOME:-$HOME/.config}/ndotshell"
        file="$dir/clipboard-history.json"
        ;;
    *)
        dir="${XDG_STATE_HOME:-$HOME/.local/state}/ndotshell"
        file="$dir/$name.json"
        ;;
esac

case "$mode" in
    save)
        [ -n "$3" ] || exit 1
        mkdir -p "$dir" || exit 1
        tmp="$file.tmp.$$"
        printf '%s' "$3" > "$tmp" || { rm -f "$tmp"; exit 1; }
        mv "$tmp" "$file"
        ;;
    load)
        [ -f "$file" ] && cat "$file"
        ;;
esac
