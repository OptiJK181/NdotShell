pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// Clipboard history — designed to be PRIVATE first:
//   • Nothing is written to disk unless you PIN an item (pinned only).
//   • Strings that look like secrets (passwords, API keys, tokens, cards,
//     Bearer auth, private keys) are never recorded.
//   • `privateMode` pauses recording entirely (IPC: clipboard private on|off).
//   • The history is wiped automatically when the screen locks.
// Access: ClipboardHistoryService.history, .add(), .remove(), .clear(),
// .pin(), .copyToClipboard(), .wipe(), .privateMode.
Singleton {
    id: root

    // [{ id, type: "text"|"image", content, pinned, timestamp }]
    property var history: []
    property int maxItems: 50
    // Recording state: true while the watcher follows the clipboard.
    readonly property bool monitoring: monitorTimer.running
    // Incognito: nothing new is recorded while on. Items already in the
    // history stay (clear them with wipe()).
    property bool privateMode: false

    readonly property string script: Directories.script("state/service-state.sh")

    // ===== privacy: what never gets recorded ================================
    // Matches the shapes secrets usually come in. Kept deliberately broad —
    // a false positive only means that one copy is not remembered.
    readonly property var sensitivePatterns: [
        /(?:^|[^\w])(?:password|passwd|pwd|secret|token|api[_-]?key|apikey|access[_-]?key|private[_-]?key|client[_-]?secret|auth)\s*[:=]/i,
        /\b(sk|pk|ghp|gho|github_pat|xox[bpars]|AKIA|ASIA)[-_][A-Za-z0-9_-]{10,}\b/,   // api tokens
        /Bearer\s+[A-Za-z0-9._\-]{20,}/i,                                             // auth headers
        /\bBEGIN [A-Z ]*PRIVATE KEY\b/,                                               // keys
        /\b(?:\d[ -]?){13,19}\b/,                                                     // card numbers
        /\b[A-Fa-f0-9]{32,}\b/,                                                       // long hex (hashes/keys)
        /\beyJ[A-Za-z0-9_-]{10,}\./                                                   // JWTs
    ]

    function looksSensitive(text) {
        if (typeof text !== "string" || text === "")
            return true
        for (let i = 0; i < sensitivePatterns.length; i++)
            if (sensitivePatterns[i].test(text))
                return true
        return false
    }

    // Wipe everything (history + any pinned item persisted on disk).
    function wipe() {
        root.history = []
        writer.exec(["sh", root.script, "save", "clipboard-history", "[]"])
        historyChanged()
    }

    function clear() {
        // Clear unpinned only; pinned survive unless wipe() is used.
        root.history = root.history.filter(function(item) { return item.pinned })
        root.save()
        historyChanged()
    }

    function load() {
        // Disk holds pinned items only: the transient history is RAM-only,
        // so a stolen disk or a shared screenshot of ~/.config says nothing
        // about what you copied.
        loader.running = true
    }

    function save() {
        // Pinned items only, never the transient history.
        const pinned = root.history.filter(function(item) { return item.pinned })
        writer.exec(["sh", root.script, "save", "clipboard-history",
                     JSON.stringify(pinned.map(function(item) {
                         return { id: item.id, type: item.type, content: item.content,
                                  pinned: true, timestamp: item.timestamp }
                     }))])
    }

    function startMonitoring() {
        if (monitorTimer.running) return
        monitorTimer.running = true
    }

    function stopMonitoring() {
        monitorTimer.running = false
    }

    function setPrivateMode(on) {
        root.privateMode = on === true
    }

    function togglePrivate() {
        root.privateMode = !root.privateMode
        return root.privateMode
    }

    function add(content, type) {
        if (root.privateMode)
            return
        if (type !== "image" && root.looksSensitive(content))
            return
        if (!content || (type === "text" && content.trim() === ""))
            return
        // Same text again: move to top.
        for (var i = 0; i < root.history.length; i++) {
            if (!root.history[i].pinned && root.history[i].type === type && root.history[i].content === content) {
                const item = root.history.splice(i, 1)[0]
                item.timestamp = Date.now()
                root.history.unshift(item)
                historyChanged()
                return
            }
        }
        root.history.unshift({
            id: "clip_" + Date.now() + "_" + Math.random().toString(36).slice(2, 11),
            type: type,
            content: type === "image" ? content : String(content).slice(0, 10000),
            pinned: false,
            timestamp: Date.now()
        })
        // Drop oldest unpinned past the limit.
        if (root.history.length > root.maxItems) {
            for (var j = root.history.length - 1; j >= 0; j--) {
                if (!root.history[j].pinned) {
                    root.history.splice(j, 1)
                    break
                }
            }
        }
        historyChanged()
    }

    function remove(id) {
        for (var i = 0; i < root.history.length; i++) {
            if (root.history[i].id === id) {
                root.history.splice(i, 1)
                root.save()
                historyChanged()
                return
            }
        }
    }

    function pin(id) {
        for (var i = 0; i < root.history.length; i++) {
            if (root.history[i].id === id) {
                root.history[i].pinned = !root.history[i].pinned
                root.save()   // pinned goes to disk; unpin removes it again
                historyChanged()
                return
            }
        }
    }

    function copyToClipboard(id) {
        for (var i = 0; i < root.history.length; i++) {
            if (root.history[i].id === id) {
                Quickshell.copyToClipboard(root.history[i].content)
                const item = root.history.splice(i, 1)[0]
                item.timestamp = Date.now()
                root.history.unshift(item)
                historyChanged()
                return
            }
        }
    }

    Component.onCompleted: root.load()

    // Pinned items only, read once at startup.
    Process {
        id: loader
        command: ["sh", root.script, "load", "clipboard-history"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "")
                    return
                try {
                    const list = JSON.parse(text)
                    root.history = list.filter(function(item) { return item.pinned === true })
                } catch (e) {
                    console.warn("ClipboardHistoryService: bad pinned JSON:", e)
                }
            }
        }
    }

    Process { id: writer }

    // Wipe the history the moment the screen locks.
    Connections {
        target: LockState
        function onLockedChanged() {
            if (LockState.locked)
                root.wipe()
        }
    }

    // Local-only watcher: polls the clipboard, no network, no telemetry.
    property string lastText: ""
    Timer {
        id: monitorTimer
        interval: 1000
        running: false
        repeat: true
        onTriggered: {
            const text = Quickshell.readFromClipboard()
            if (text && text !== root.lastText) {
                root.lastText = text
                root.add(text, "text")
            }
        }
    }

    // ===== IPC: modo privado, limpiar, estado =====
    IpcHandler {
        target: "clipboard"

        // Toggle private mode AND show the OSD (the Super + P animation).
        function toggle(): string {
            const on = root.togglePrivate()
            OSDSource.showPrivate(on)
            return on ? "private: on" : "private: off"
        }

        function private(mode: string): string {
            const on = mode === "on" || mode === "true" || mode === "1"
            root.setPrivateMode(on)
            OSDSource.showPrivate(on)
            return root.privateMode ? "private: on" : "private: off"
        }

        function wipe(): void {
            root.wipe()
        }

        function clear(): void {
            root.clear()
        }

        function status(): string {
            return root.privateMode ? "private" : (root.monitoring ? "recording" : "off")
        }
    }
}