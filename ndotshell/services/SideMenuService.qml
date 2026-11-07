pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// Side drawers, Caelestia-style: touch (hover) the screen edge and the
// panel slides out; move away and it slides back. A keybind/IPC toggle
// "pins" a drawer open (stays until you toggle again or press Esc).
//
//   gaming — right edge — Super + Shift + G
//   work   — left  edge — Super + Shift + W
//
// One open at a time. The edge hotspots are owned by the drawer windows
// themselves (see GamingDrawer/WorkDrawer's `hotspot`); they call
// hoverEnter()/hoverLeave() here, and the drawers report cardHovered.
// IPC target "sidemenu".
Singleton {
    id: root

    // "" | "gaming" | "work" — which drawer is (fully or partly) on screen
    property string open: ""
    // A drawer pinned by its keybind/IPC: stays open however the pointer moves.
    property string pinned: ""

    // ===== Dynamic Island: 100% manual =====
    // side.island (Ajustes) habilita la función; islandOpen es el estado
    // visible (keybind Super + Shift + D, o ipc call island toggle).
    property bool islandOpen: false

    function toggleIsland() {
        if (!SettingsService.flag("side.island"))
            return
        root.islandOpen = !root.islandOpen
    }

    IpcHandler {
        target: "island"

        function toggle(): void { root.toggleIsland() }
        function show(): void {
            if (SettingsService.flag("side.island")) root.islandOpen = true
        }
        function hide(): void { root.islandOpen = false }
        function status(): string {
            if (!SettingsService.flag("side.island")) return "disabled"
            return root.islandOpen ? "open" : "hidden"
        }
    }

    // Hover bookkeeping (driven by the drawer windows).
    property bool hotspotHovered: false
    property bool cardHovered: false
    property bool catcherHovered: false

    // Grace timer: pointer left everything for a moment → close (unless pinned).
    readonly property bool abandoned: open !== "" && !pinned
        && !hotspotHovered && !cardHovered && !catcherHovered

    onAbandonedChanged: {
        if (abandoned)
            grace.restart()
        else
            grace.stop()
    }

    Timer {
        id: grace
        interval: 450
        onTriggered: root.hide()
    }

    function show(name) {
        if (name !== "gaming" && name !== "work") return
        if (root.pinned !== "" && root.pinned !== name) root.pinned = ""
        root.open = name
    }

    function hide() {
        root.open = ""
        root.pinned = ""
        root.hotspotHovered = false
        root.cardHovered = false
        root.catcherHovered = false
    }

    function toggle(name) {
        if (root.open === name && root.pinned === name) {
            root.hide()
            return
        }
        root.pinned = name
        root.open = name
    }

    // Called by the hotspot strip when the pointer touches the edge.
    function hoverEnter(name) {
        root.hotspotHovered = true
        if (root.open === "") root.show(name)
    }

    function hoverLeave() {
        root.hotspotHovered = false
    }

    IpcHandler {
        target: "sidemenu"

        function gaming(): void { root.toggle("gaming") }
        function work(): void { root.toggle("work") }
        function toggle(name: string): void { root.toggle(name) }
        function show(name: string): void { root.pinned = name; root.show(name) }
        function close(): void { root.hide() }
        function status(): string {
            if (root.open === "") return "closed"
            return root.open + (root.pinned === root.open ? " (pinned)" : "")
        }
    }
}