pragma Singleton
import QtQuick
import Quickshell

// Pomodoro timer: 25/5 cycles, persistent stats, notifications
Singleton {
    id: root

    enum State { Idle, Work, Break, LongBreak }
    property int state: State.Idle
    property int timeLeft: 25 * 60      // seconds
    property int workDuration: 25 * 60
    property int breakDuration: 5 * 60
    property int longBreakDuration: 15 * 60
    property int cyclesBeforeLongBreak: 4
    property int completedCycles: 0
    property int totalWorkTime: 0       // seconds today
    property bool autoStartBreaks: true
    property bool autoStartWork: false

    // Persisted stats
    property string statsPath: ""

    Component.onCompleted: {
        // Construct path without FileSystem
        var homeDir = Qt.resolvedUrl("").replace("file://", "").replace(/\/[^\/]*$/, "");
        root.statsPath = homeDir + "/.cache/ndotshell/pomodoro-stats.json";
        root.loadStats()
        root.reset()
    }

    function loadStats() {
        var file = readFile(root.statsPath)
        if (file !== "") {
            try {
                var data = JSON.parse(file)
                root.completedCycles = data.completedCycles || 0
                root.totalWorkTime = data.totalWorkTime || 0
                root.totalCyclesAllTime = data.totalCyclesAllTime || 0
                root.totalWorkTimeAllTime = data.totalWorkTimeAllTime || 0
                // Reset daily counters if date changed
                var today = Qt.formatDate(new Date(), "yyyy-MM-dd")
                if (data.lastDate !== today) {
                    root.completedCycles = 0
                    root.totalWorkTime = 0
                }
            } catch (e) {}
        }
    }

    function saveStats() {
        var data = {
            completedCycles: root.completedCycles,
            totalWorkTime: root.totalWorkTime,
            totalCyclesAllTime: root.totalCyclesAllTime,
            totalWorkTimeAllTime: root.totalWorkTimeAllTime,
            lastDate: Qt.formatDate(new Date(), "yyyy-MM-dd")
        }
        writeFile(root.statsPath, JSON.stringify(data))
    }

    function startWork() {
        if (root.state !== State.Idle && root.state !== State.Work) return
        root.state = State.Work
        root.timeLeft = root.workDuration
        timer.running = true
    }

    function startBreak() {
        var isLong = (root.completedCycles + 1) % root.cyclesBeforeLongBreak === 0
        root.state = isLong ? State.LongBreak : State.Break
        root.timeLeft = isLong ? root.longBreakDuration : root.breakDuration
        timer.running = true
    }

    function toggle() {
        if (root.state === State.Idle) root.startWork()
        else if (timer.running) timer.running = false
        else timer.running = true
    }

    function reset() {
        timer.running = false
        root.state = State.Idle
        root.timeLeft = root.workDuration
    }

    function skip() {
        if (root.state === State.Work) {
            root.completedCycles++
            root.totalWorkTime += root.workDuration - root.timeLeft
            root.totalWorkTimeAllTime += root.workDuration - root.timeLeft
            root.totalCyclesAllTime++
            root.saveStats()
            if (root.autoStartBreaks) root.startBreak()
            else root.reset()
            notify("work_done")
        } else {
            root.reset()
        }
    }

    Timer {
        id: timer
        interval: 1000
        running: false
        repeat: true
        onTriggered: {
            if (root.timeLeft > 0) {
                root.timeLeft--
            } else {
                root.skip()
            }
        }
    }

    function notify(kind) {
        var msg = ""
        var icon = "schedule"
        if (kind === "work_done") {
            msg = qsTr("¡Pomodoro completado! %1 ciclos hoy.").arg(root.completedCycles)
            icon = "check_circle"
        } else if (kind === "break_done") {
            msg = qsTr("Descanso terminado. ¿Empezamos otro?")
            icon = "coffee"
        }
        Quickshell.execDetached(["notify-send", "-a", "ndotshell", "-i", "material:" + icon,
            "Pomodoro", msg])
    }

    // Format mm:ss
    function format() {
        var m = Math.floor(root.timeLeft / 60)
        var s = root.timeLeft % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    // State label
    readonly property string stateLabel: {
        switch (root.state) {
        case State.Work: return qsTr("Trabajo")
        case State.Break: return qsTr("Descanso")
        case State.LongBreak: return qsTr("Descanso largo")
        default: return qsTr("Listo")
        }
    }

    // File I/O helpers (since FileSystem import is blackholed)
    function readFile(path) {
        var process = Qt.createComponent("file:///usr/bin/cat");
        // Use shell command to read file
        var result = ""
        // Use a simple approach - we can't easily read files without FileSystem
        // This is a placeholder - in practice we'd use a Process
        return ""
    }

    function writeFile(path, content) {
        // Use shell command to write file
        // This is a placeholder - in practice we'd use a Process
    }
}