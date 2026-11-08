#!/usr/bin/env bash
# ryoku-hub-open — abre el Ryoku Hub con daemon TRANSEÚNTE (NdotShell).
#
# El daemon de ryoku-shell "supervisa la Quickshell desktop": si se deja
# vivo, spawnéea (y RESPAWNEA) la shell de Ryoku => 2 barras + 2 docks
# peleando con NdotShell. Este script lo levanta SOLO lo que tarda el
# hub en abrir, y al final lo mata junto con su watcher y la shell que
# haya spawnado. Si el daemon ya estaba vivo (sesión Ryoku real), no se
# toca nada.
#
# Usado por: la entrada ryoku-hub.desktop override (~/.local/share/
# applications), el botón de Ajustes → Escritorio → Ryoku Services y
# la terminal (ryoku-hub-open).
#
# Truco anti-auto-match: el kill usa indirección (D="ryoku-shell") para
# que ningún patrón machée el texto literal de este propio script.

S="$XDG_RUNTIME_DIR/ryoku-shell.sock"
D="ryoku-shell"
spawned=0
DPID=""

if ! "$D" status 2>/dev/null | grep -q running; then
    spawned=1
    setsid "$D" daemon >/dev/null 2>&1 < /dev/null &
    DPID=$!
    i=0
    while ! [ -S "$S" ] && [ "$i" -lt 20 ]; do
        sleep 0.15
        i=$((i + 1))
    done
fi

"$D" hub open >/dev/null 2>&1 || \
    qs -p /usr/share/ryoku/config/quickshell/hub/shell.qml >/dev/null 2>&1

# margen para que el hub termine de nacer con backend completo
sleep 2

if [ "$spawned" -eq 1 ]; then
    kill "$DPID" 2>/dev/null
    for p in $(pgrep -x "$D" 2>/dev/null); do kill "$p" 2>/dev/null; done
    pkill -f "wm-hyprland watc[h]" 2>/dev/null
    sleep 0.5
    qs kill -c shell 2>/dev/null
    for p in $(pgrep -x "$D" 2>/dev/null); do kill "$p" 2>/dev/null; done
fi

exit 0
