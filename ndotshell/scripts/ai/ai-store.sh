#!/bin/sh

# ai-store.sh — private storage for the AI widget.
#
#   ai-store.sh load          print the stored JSON (or nothing)
#   ai-store.sh save          read JSON from stdin and replace the file
#   ai-store.sh clear         forget everything (config + history + key)
#
# Lives in ${XDG_CONFIG_HOME:-~/.config}/ndotshell/ai.json with mode 600:
# it holds the API key and the conversation history, so it is private by
# default and the widget warns about backups/dotfiles.
#
# Written atomically (temp file + mv) so a crash mid-save cannot leave a
# half file. The key never travels as an argv argument (visible in `ps`):
# both directions use stdin/stdout.

mode="$1"
dir="${XDG_CONFIG_HOME:-$HOME/.config}/ndotshell"
file="$dir/ai.json"

case "$mode" in
    save)
        umask 077
        mkdir -p "$dir" || exit 1
        tmp="$file.tmp.$$"
        # One line of JSON (Quickshell's Process keeps stdin open while it
        # runs, so we read a line instead of waiting for EOF).
        IFS= read -r payload
        printf '%s' "$payload" > "$tmp" || exit 1
        chmod 600 "$tmp" 2>/dev/null
        mv -- "$tmp" "$file" || exit 1
        ;;
    load)
        [ -f "$file" ] && cat "$file"
        exit 0
        ;;
    clear)
        rm -f -- "$file"
        ;;
    *)
        echo "usage: $0 load|save|clear" >&2
        exit 2
        ;;
esac
