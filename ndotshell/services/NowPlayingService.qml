pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// The Now Playing widget's state — where the card sits, how big it is and
// whether it is on the desktop. Kept as its own singleton (like
// TodoService.qml, CalendarCardService.qml) so anything else can add it
// without touching NowPlayingWidget.qml:
//
//   import qs.services
//   ...
//   NowPlayingService.setShown(true)
//
// The track itself is NOT kept here: it comes live from MediaSource.qml
// (MPRIS). Only the card's own look / place is remembered, so a song changing
// never writes to disk.
//
// Persistence follows the same convention as TodoService: a tiny shell script
// (nowplaying-state.sh) run as a Process. Saves are debounced, so dragging the
// card does not hit the disk on every pixel.
Singleton {
    id: root

    // False until the saved state has been read. Nothing is written before
    // then, so a fresh start does not overwrite what is on disk.
    property bool loaded: false

    // Off until you add it: Edit Desktop's shelf, Settings -> Desktop, or
    //   qs -c ndotshell ipc call nowplaying toggle
    property bool shown: false

    // The screen the card lives on (a WidgetClones copy uses its own spot).
    property string screenName: ""

    // Position in design pixels. -1 = never placed; the widget picks a default.
    property real posX: -1
    property real posY: -1
    // The shell scale posX / posY were saved at (0 = saved before it was kept).
    property real posScale: 0

    // "full" is the wide card with the cover beside the text; "2x2" is the
    // tall, centred card. Remembered across restarts.
    property string size: "full"
    readonly property bool small: root.size === "2x2"

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

    function setSize(value) {
        const v = value === "2x2" || value === "small" ? "2x2" : "full"
        if (v === root.size)
            return
        root.size = v
        root.persist()
    }

    function toggleSize() {
        root.setSize(root.small ? "full" : "2x2")
    }

    // ===== persistence =====
    readonly property string script: Directories.script("state/nowplaying-state.sh")

    function snapshot() {
        return JSON.stringify({
            x: root.posX,
            y: root.posY,
            scale: root.posScale,
            shown: root.shown,
            size: root.size,
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
            root.shown = s.shown === true
            root.size = s.size === "2x2" ? "2x2" : "full"
        } catch (e) {
            // No file yet (first run) or an unreadable one: start off.
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
    // TodoService's `saver`, so the *last* state is what ends up on disk.
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
