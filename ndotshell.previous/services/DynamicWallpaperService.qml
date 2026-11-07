pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Dynamic wallpaper: changes based on time of day
// Supports: morning, day, evening, night folders or single images with time ranges
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

    property string configPath: ""

    Component.onCompleted: {
        root.configPath = FileSystem.configDir + "/ndotshell/dynamic-wallpaper.json"
        root.load()
        root.update()
        // Check every minute
        checkTimer.running = true
    }

    function load() {
        var file = FileSystem.readFile(root.configPath)
        if (file !== "") {
            try {
                var data = JSON.parse(file)
                root.enabled = data.enabled || false
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
            } catch (e) {}
        }
    }

    function save() {
        var data = {
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
        FileSystem.writeFile(root.configPath, JSON.stringify(data))
    }

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

    // Determine current period based on hour
    function currentPeriod() {
        var hour = new Date().getHours()
        if (hour >= root.nightStart || hour < root.morningStart) return "night"
        if (hour < root.dayStart) return "morning"
        if (hour < root.eveningStart) return "day"
        return "evening"
    }

    function currentImage() {
        var period = root.currentPeriod()
        switch (period) {
        case "morning": return root.morningPath
        case "day": return root.dayPath
        case "evening": return root.eveningPath
        case "night": return root.nightPath
        }
        return ""
    }

    function update() {
        if (!root.enabled) return
        var img = root.currentImage()
        if (img !== "") {
            // Use the wallpaper service to set it
            WallpaperService.setWallpaper(img, "dynamic")
        }
    }

    // Manual mode: user picks from gallery
    function setManual(path) {
        root.mode = "manual"
        WallpaperService.setWallpaper(path, "dynamic")
        root.save()
    }

    Timer {
        id: checkTimer
        interval: 60000 // every minute
        running: true
        repeat: true
        onTriggered: root.update()
    }
}