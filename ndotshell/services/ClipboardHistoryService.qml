pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history: stores text and images, persists across restarts
// Access: ClipboardHistoryService.history (array), .add(), .remove(), .clear(), .pin()
Singleton {
    id: root

    property var history: []          // [{ id, type: "text"|"image", content, pinned, timestamp }]
    property int maxItems: 50
    property bool monitoring: false

    readonly property string storePath: FileSystem.mkpath(FileSystem.cacheDir + "/ndotshell/clipboard-history.json")

    // Load on startup
    Component.onCompleted: root.load()

    function load() {
        var file = FileSystem.readFile(storePath)
        if (file !== "") {
            try {
                root.history = JSON.parse(file)
            } catch (e) {
                root.history = []
            }
        }
        // Start monitoring after load
        root.startMonitoring()
    }

    function save() {
        FileSystem.writeFile(storePath, JSON.stringify(root.history))
    }

    function startMonitoring() {
        if (root.monitoring) return
        root.monitoring = true
        // Poll clipboard every 500ms (wlr-clipboard-history approach)
        monitorTimer.running = true
    }

    function stopMonitoring() {
        root.monitoring = false
        monitorTimer.running = false
    }

    function add(content, type) {
        if (!content || (type === "text" && content.trim() === "")) return
        // Avoid duplicates (unless pinned)
        for (var i = 0; i < root.history.length; i++) {
            if (!root.history[i].pinned && root.history[i].type === type && root.history[i].content === content) {
                // Move to top
                var item = root.history.splice(i, 1)[0]
                item.timestamp = Date.now()
                root.history.unshift(item)
                root.save()
                root.historyChanged()
                return
            }
        }
        var item = {
            id: "clip_" + Date.now() + "_" + Math.random().toString(36).substr(2, 9),
            type: type,
            content: type === "image" ? content : content.substr(0, 10000), // limit text
            pinned: false,
            timestamp: Date.now()
        }
        root.history.unshift(item)
        if (root.history.length > root.maxItems) {
            // Remove oldest non-pinned
            for (var j = root.history.length - 1; j >= 0; j--) {
                if (!root.history[j].pinned) {
                    root.history.splice(j, 1)
                    break
                }
            }
        }
        root.save()
        root.historyChanged()
    }

    function remove(id) {
        for (var i = 0; i < root.history.length; i++) {
            if (root.history[i].id === id) {
                root.history.splice(i, 1)
                root.save()
                root.historyChanged()
                return
            }
        }
    }

    function clear() {
        root.history = root.history.filter(function(item) { return item.pinned })
        root.save()
        root.historyChanged()
    }

    function pin(id) {
        for (var i = 0; i < root.history.length; i++) {
            if (root.history[i].id === id) {
                root.history[i].pinned = !root.history[i].pinned
                root.save()
                root.historyChanged()
                return
            }
        }
    }

    function copyToClipboard(id) {
        for (var i = 0; i < root.history.length; i++) {
            if (root.history[i].id === id) {
                Quickshell.copyToClipboard(root.history[i].content)
                // Move to top
                var item = root.history.splice(i, 1)[0]
                item.timestamp = Date.now()
                root.history.unshift(item)
                root.save()
                root.historyChanged()
                return
            }
        }
    }

    // Poll clipboard using wl-clipboard (wl-paste)
    Timer {
        id: monitorTimer
        interval: 500
        running: false
        repeat: true
        onTriggered: {
            // Check text
            var text = Quickshell.readFromClipboard()
            if (text && text !== root.lastText) {
                root.lastText = text
                root.add(text, "text")
            }
            // Check image (wl-paste --type image/png)
            // Note: wl-paste blocks if no data, so we use a quick timeout
            // For images, we rely on the user copying via the widget's "copy image" action
        }
    }
    property string lastText: ""
}