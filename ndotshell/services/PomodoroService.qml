pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// Pomodoro timer: 25/5 cycles, persistent stats, notifications.
// Stats persist via scripts/state/service-state.sh (Process + shell I/O),
// so they survive restarts; daily counters reset when the date changes.
Singleton {
    id: root

    enum State { Idle, Work, Break, LongBreak }
    property int state: State.Idle
    property int timeLeft: 25 * 60
    property int workDuration: 25 * 60
    property int breakDuration: 5 * 60
    property int longBreakDuration: 15 * 60
    property int cyclesBeforeLongBreak: 4
    property int completedCycles: 0
    property int totalWorkTime: 0       // seconds today
    property bool autoStartBreaks: true
    property bool autoStartWork: false

    property int totalCyclesAllTime: 0
    property int totalWorkTimeAllTime: 0
    // Readable from outside (WorkDrawer's play/pause icon): the Timer's
    // `running` bit, mirrored here because ids are not accessible outside.
    property bool running: false
    // Idle flag for outside use (enum members aren't reachable cross-file).
    readonly property bool idle: state === State.Idle

    readonly property string script: Directories.script("state/service-state.sh")
    readonly property bool loaded: loader.loaded

    // The notification when the timer runs out (one per state change).
    function notify(kind) {
        const msg = kind === "work_done"
            ? qsTr("¡Ciclo completado! %1 ciclos hoy.").arg(root.completedCycles)
            : qsTr("Descanso terminado. ¿Otra ronda?")
        const icon = kind === "work_done" ? "check_circle" : "coffee"
        Quickshell.execDetached(["notify-send", "-a", "ndotshell", "-i", "material:" + icon,
            "Pomodoro", msg])
    }

    function loadStats() {
        loader.running = true
    }

    function saveStats() {
        const data = {
            completedCycles: root.completedCycles,
            totalWorkTime: root.totalWorkTime,
            totalCyclesAllTime: root.totalCyclesAllTime,
            totalWorkTimeAllTime: root.totalWorkTimeAllTime,
            lastDate: Qt.formatDate(new Date(), "yyyy-MM-dd")
        }
        writer.exec(["sh", root.script, "save", "pomodoro-stats", JSON.stringify(data)])
    }

    // Load once at startup.
    Process {
        id: loader
        command: ["sh", root.script, "load", "pomodoro-stats"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "")
                    return
                try {
                    const data = JSON.parse(text)
                    root.completedCycles = data.completedCycles || 0
                    root.totalWorkTime = data.totalWorkTime || 0
                    root.totalCyclesAllTime = data.totalCyclesAllTime || 0
                    root.totalWorkTimeAllTime = data.totalWorkTimeAllTime || 0
                    // Reset daily counters if the date changed.
                    const today = Qt.formatDate(new Date(), "yyyy-MM-dd")
                    if (data.lastDate !== today) {
                        root.completedCycles = 0
                        root.totalWorkTime = 0
                    }
                } catch (e) {
                    console.warn("PomodoroService: bad stats JSON:", e)
                }
            }
        }
    }

    // Writes; one at a time, the last request wins.
    Process { id: writer }

    function startWork() {
        if (root.state !== State.Idle && root.state !== State.Work) return
        root.state = State.Work
        root.timeLeft = root.workDuration
        timer.running = true
        root.running = true
    }

    function startBreak() {
        const isLong = (root.completedCycles + 1) % root.cyclesBeforeLongBreak === 0
        root.state = isLong ? State.LongBreak : State.Break
        root.timeLeft = isLong ? root.longBreakDuration : root.breakDuration
        timer.running = true
        root.running = true
    }

    function toggle() {
        if (root.state === State.Idle) {
            root.startWork()
            return
        }
        timer.running = !timer.running
        root.running = timer.running
    }

    function reset() {
        timer.running = false
        root.running = false
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
            root.notify("work_done")
        } else if (root.state !== State.Idle) {
            if (root.autoStartWork) root.startWork()
            else root.reset()
            root.notify("break_done")
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

    function format() {
        const m = Math.floor(root.timeLeft / 60)
        const s = root.timeLeft % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    readonly property string stateLabel: {
        switch (root.state) {
        case State.Work: return qsTr("Trabajo")
        case State.Break: return qsTr("Descanso")
        case State.LongBreak: return qsTr("Descanso largo")
        default: return qsTr("Listo")
        }
    }
}