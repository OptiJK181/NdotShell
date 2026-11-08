pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// The AI pet widget's state — where the card sits and whether it is on the
// desktop. Its own singleton (like NowPlayingService.qml, TodoService.qml) so
// Edit Desktop, Settings and the ipc can all drive it without touching the
// widget itself:
//
//   import qs.services
//   ...
//   AiWidgetService.setShown(true)
//
// The conversation is NOT kept here: it lives in AiService (ai.json). Only
// the card's own place is remembered, so a message arriving never writes to
// disk.
//
// Persistence follows the same convention as NowPlayingService: a tiny shell
// script (aiwidget-state.sh) run as a Process. Saves are debounced, so
// dragging the card does not hit the disk on every pixel.
Singleton {
    id: root

    // False until the saved state has been read. Nothing is written before
    // then, so a fresh start does not overwrite what is on disk.
    property bool loaded: false

    // The pet is the desktop's mascot: on unless you took it off (Edit
    // Desktop's shelf, Ajustes → IA, or the ipc).
    property bool shown: true

    // The screen the card lives on (a WidgetClones copy uses its own spot).
    property string screenName: ""

    // Position in design pixels. -1 = never placed; the widget picks a default.
    property real posX: -1
    property real posY: -1
    // The shell scale posX / posY were saved at (0 = saved before it was kept).
    property real posScale: 0

    function setShown(value) {
        root.shown = value === true
        root.persist()
    }

    function setPosition(x, y, scale) {
        if (!root.loaded)
            return
        root.posX = x
        root.posY = y
        if (typeof scale === "number" && scale > 0)
            root.posScale = scale
        saveTimer.restart()
    }

    function clearPosition() {
        root.posX = -1
        root.posY = -1
        root.posScale = 0
        root.persist()
    }

    // ===== persistence =====
    readonly property string script: Directories.script("state/aiwidget-state.sh")

    function snapshot() {
        return JSON.stringify({
            x: root.posX,
            y: root.posY,
            scale: root.posScale,
            shown: root.shown,
            screen: root.screenName
        })
    }

    function restore(text) {
        try {
            const s = JSON.parse(text)
            if (typeof s.x === "number")
                root.posX = s.x
            if (typeof s.y === "number")
                root.posY = s.y
            if (typeof s.scale === "number" && s.scale > 0)
                root.posScale = s.scale
            if (typeof s.screen === "string")
                root.screenName = s.screen
            root.shown = s.shown !== false
        } catch (e) {
            // No file yet (first run): the pet starts on.
        }
        root.loaded = true
    }

    // Runs once, at startup.
    Process {
        running: true
        command: ["sh", root.script, "load"]
        stdout: StdioCollector {
            onStreamFinished: root.restore(text)
        }
    }

    function persist() {
        if (root.loaded)
            saveTimer.restart()
    }

    Timer {
        id: saveTimer
        interval: 300
        onTriggered: saver.save(root.snapshot())
    }

    // Fire-and-forget save. Queues at most one pending snapshot behind an
    // in-flight save rather than dropping it — same reasoning as
    // NowPlayingService's `saver`, so the *last* state is what ends on disk.
    Process {
        id: saver

        property var pending: null

        function save(json) {
            if (saver.running) {
                saver.pending = json
                return
            }
            saver.pending = null
            saver.exec(["sh", root.script, "save", json])
        }

        onExited: {
            if (saver.pending !== null) {
                const json = saver.pending
                saver.pending = null
                saver.exec(["sh", root.script, "save", json])
            }
        }
    }
}
