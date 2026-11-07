pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// Side drawers: two edge panels, 100% purpose-built.
//   gaming — right edge: game mode, recorder, keep awake, live stats
//   work   — left edge: pomodoro, focus, clipboard privacy, quick to-do
// One open at a time; Esc or clicking outside closes. IPC target "sidemenu".
Singleton {
    id: root

    property string open: ""          // "" | "gaming" | "work"

    function toggle(name) {
        root.open = (root.open === name) ? "" : name
    }

    function show(name) { root.open = name }
    function hide() { root.open = "" }

    IpcHandler {
        target: "sidemenu"

        function toggle(name: string): void { root.toggle(name) }
        function gaming(): void { root.toggle("gaming") }
        function work(): void { root.toggle("work") }
        function close(): void { root.hide() }
        function status(): string { return root.open === "" ? "closed" : root.open }
    }
}
