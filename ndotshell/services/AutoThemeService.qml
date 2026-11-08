pragma Singleton
import QtQuick
import Quickshell
import qs.services

// Auto dark/light: cambia el tema según la hora del día.
// Día (07:00-20:00) → light · Noche (20:00-07:00) → dark.
// Usar SettingsService para persistencia (no FileSystem).
Singleton {
    id: root

    property bool enabled: false
    property int dayStart: 7         // 07:00 → light
    property int nightStart: 20     // 20:00 → dark
    property bool isDay: false

    Component.onCompleted: {
        root.enabled = SettingsService.flag("autoTheme.enabled")
        root.dayStart = SettingsService.get("autoTheme.dayStart")
        root.nightStart = SettingsService.get("autoTheme.nightStart")
        if (root.enabled) root.apply()
        checkTimer.running = root.enabled
    }

    function toggle() {
        root.enabled = !root.enabled
        SettingsService.set("autoTheme.enabled", root.enabled)
        checkTimer.running = root.enabled
        if (root.enabled) root.apply()
    }

    function apply() {
        const hour = new Date().getHours()
        const wantDark = hour >= root.nightStart || hour < root.dayStart
        root.isDay = !wantDark
        const current = ThemeService.mode
        if (wantDark && current !== "dark" && current !== "darker")
            ThemeService.setModeAndSystem("dark")
        else if (!wantDark && current !== "light")
            ThemeService.setModeAndSystem("light")
    }

    function setDayStart(h) {
        root.dayStart = h
        SettingsService.set("autoTheme.dayStart", h)
        root.apply()
    }

    function setNightStart(h) {
        root.nightStart = h
        SettingsService.set("autoTheme.nightStart", h)
        root.apply()
    }

    Timer {
        id: checkTimer
        interval: 60000
        running: false
        repeat: true
        onTriggered: {
            if (root.enabled) root.apply()
        }
    }
}