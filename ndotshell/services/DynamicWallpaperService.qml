pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// Dynamic wallpaper: one image per period of the day (morning / day /
// evening / night), swapped on a timer with a smooth transition. Config
// persists via scripts/state/service-state.sh (shell I/O — the
// Quickshell.Io FileSystem singleton is not reachable from here).
Singleton {
    id: root

    property bool enabled: false
    property string mode: "time"        // "time" (auto by hour), "manual" (user picks)
    property string morningPath: ""
    property string dayPath: ""
    property string eveningPath: ""
    property string nightPath: ""
    property int morningStart: 6        // 06:00
    property int dayStart: 10           // 10:00
    property int eveningStart: 18       // 18:00
    property int nightStart: 22         // 22:00
    property int transitionDuration: 30 // minutes for crossfade

    readonly property string script: Directories.script("state/service-state.sh")
    property bool loaded: false

    Component.onCompleted: {
        loader.running = true
        // Check every minute (cheap: an in-process hour compare per tick).
        checkTimer.running = true
    }

    function load() {
        loader.running = true
    }

    function save() {
        const data = {
            enabled: root.enabled,
            mode: root.mode,
            morningPath: root.morningPath,
            dayPath: root.dayPath,
            eveningPath: root.eveningPath,
            nightPath: root.nightPath,
            morningStart: root.morningStart,
            dayStart: root.dayStart,
            eveningStart: root.eveningStart,
            nightStart: root.nightStart,
            transitionDuration: root.transitionDuration
        }
        writer.exec(["sh", root.script, "save", "dynamic-wallpaper", JSON.stringify(data)])
    }

    Process {
        id: loader
        command: ["sh", root.script, "load", "dynamic-wallpaper"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.loaded = true
                if (text.trim() === "")
                    return
                try {
                    const data = JSON.parse(text)
                    root.enabled = data.enabled === true
                    root.mode = data.mode || "time"
                    root.morningPath = data.morningPath || ""
                    root.dayPath = data.dayPath || ""
                    root.eveningPath = data.eveningPath || ""
                    root.nightPath = data.nightPath || ""
                    root.morningStart = data.morningStart || 6
                    root.dayStart = data.dayStart || 10
                    root.eveningStart = data.eveningStart || 18
                    root.nightStart = data.nightStart || 22
                    root.transitionDuration = data.transitionDuration || 30
                    root.update()
                } catch (e) {
                    console.warn("DynamicWallpaperService: bad config JSON:", e)
                }
            }
        }
    }

    Process { id: writer }

    function setImage(period, path) {
        switch (period) {
        case "morning": root.morningPath = path; break
        case "day": root.dayPath = path; break
        case "evening": root.eveningPath = path; break
        case "night": root.nightPath = path; break
        }
        root.save()
        if (root.mode === "time") root.update()
    }

    function setTime(period, hour) {
        switch (period) {
        case "morning": root.morningStart = hour; break
        case "day": root.dayStart = hour; break
        case "evening": root.eveningStart = hour; break
        case "night": root.nightStart = hour; break
        }
        root.save()
        root.update()
    }

    function toggle() {
        root.enabled = !root.enabled
        root.save()
        if (root.enabled) root.update()
    }

    // Current period from the wall clock.
    function currentPeriod() {
        const hour = new Date().getHours()
        if (hour >= root.nightStart || hour < root.morningStart) return "night"
        if (hour < root.dayStart) return "morning"
        if (hour < root.eveningStart) return "day"
        return "evening"
    }

    function currentImage() {
        switch (root.currentPeriod()) {
        case "morning": return root.morningPath
        case "day": return root.dayPath
        case "evening": return root.eveningPath
        case "night": return root.nightPath
        }
        return ""
    }

    // Apply the period's image through WallpaperService (same singleton module).
    function update() {
        if (!root.enabled) return
        const img = root.currentImage()
        if (img === "") return
        WallpaperService.setWallpaper(img)
    }

    function setManual(path) {
        root.mode = "manual"
        root.save()
        root.update()
    }

    Timer {
        id: checkTimer
        interval: 60000
        running: false
        repeat: true
        onTriggered: root.update()
    }
}