#!/bin/sh

# Helper for AiWidgetService.qml: remembers the desktop AI pet's spot and
# on / off state, so a shell restart brings it back exactly as you left it.
#
#   aiwidget-state.sh save <json>   replace the remembered state with <json>
#   aiwidget-state.sh load          print the remembered JSON (or nothing at
#                                   all, if the widget has never been used)
#
# Lives in ${XDG_STATE_HOME:-~/.local/state}/ndotshell/aiwidget.json — state,
# not data, same convention nowplaying-state.sh / todo-state.sh use. The JSON
# is passed as one real argv entry, so nothing has to be quoted. Written to a
# temp file and moved into place, so a crash mid-save can't leave half a file
# behind.

mode="$1"
dir="${XDG_STATE_HOME:-$HOME/.local/state}/ndotshell"
file="$dir/aiwidget.json"

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
