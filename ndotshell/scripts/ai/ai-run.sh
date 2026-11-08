#!/bin/sh

# ai-run.sh — the "Ejecutar" key's door: runs ONE command the AI proposed and
# the user confirmed by pressing the key. Nothing runs by itself; the button
# is the whole security model.
#
#   sh ai-run.sh <command...>
#
# The command runs detached from the shell (Quickshell.execDetached calls this
# script; it exits at once) with the user's environment. A log of everything
# executed goes to ~/.local/state/ndotshell/ai-runs.log, so "what did the
# assistant run?" always has an answer.

cmd="$*"
[ -n "$cmd" ] || exit 0

dir="${XDG_STATE_HOME:-$HOME/.local/state}/ndotshell"
mkdir -p "$dir" 2>/dev/null
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$cmd" >> "$dir/ai-runs.log" 2>/dev/null

# Detached from the caller: setsid so closing the widget never kills the app,
# and nohup semantics for stdout/stderr.
setsid sh -c "exec $cmd" >/dev/null 2>&1 < /dev/null &
exit 0
