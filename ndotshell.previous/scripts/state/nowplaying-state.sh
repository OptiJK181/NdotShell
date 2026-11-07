#!/bin/sh

# Helper for NowPlayingService.qml: remembers the desktop Now Playing
# widget's spot, size and on / off state, so a shell restart brings it back
# exactly as you left it.
#
#   nowplaying-state.sh save <json>   replace the remembered state with <json>
#   nowplaying-state.sh load          print the remembered JSON (or nothing at
#                                     all, if the widget has never been used)
#
# Lives in ${XDG_STATE_HOME:-~/.local/state}/ndotshell/nowplaying.json — state,
# not data, same convention todo-state.sh / wallpaper-state.sh use. The JSON is
# passed as one real argv entry, so nothing has to be quoted. Written to a temp
# file and moved into place, so a crash mid-save can't leave half a file behind.

mode="$1"
dir="${XDG_STATE_HOME:-$HOME/.local/state}/ndotshell"
file="$dir/nowplaying.json"

case "$mode" in
    save)
        mkdir -p "$dir" || exit 1
        printf '%s\n' "$2" > "$file.tmp" || exit 1
        mv "$file.tmp" "$file"
        ;;
    load)
        [ -f "$file" ] && cat "$file"
        exit 0
        ;;
    *)
        echo "usage: $0 save <json>|load" >&2
        exit 2
        ;;
esac
