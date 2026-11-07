import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common

// Edge hotspots (double-tap): thin strips in the screen edges that open
// their panel on a double tap. First tap pulses the accent line, second
// tap (≤420 ms) fires. Zones:
//   gaming  top-right corner  → Gaming drawer
//   work    top-left corner   → Focus drawer
//   island  right edge, mid   → Dynamic Island
//   music   bottom-right corner → Music dock
// The strips are tiny on purpose: every other pixel of the screen stays
// fully clickable.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    // "gaming" | "work" | "island" | "music"
    property string name: "gaming"
    // "corner" (top 210 px) | "mid" (right, centrado) | "bottom" (bottom 210 px)
    property string zone: "corner"
    readonly property bool atRight: name !== "work"

    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    readonly property bool topZone: zone === "corner"
    readonly property real barPad: SettingsService.flag("bar.visible")
        ? BarPositionService.thicknessFor("top") : 0

    anchors { top: topZone; bottom: zone !== "corner"; right: atRight; left: !atRight }
    implicitWidth: Math.round(10 * win.uiScale)
    implicitHeight: topZone ? Math.round(210 * win.uiScale) : 0

    // Quickshell anchors no tiene top/bottomMargin: el pad va en los hijos
    readonly property real zoneTop: topZone ? barPad
        : (zone === "mid" ? screen.height * 0.42 : screen.height - 210 * win.uiScale)
    readonly property real zoneH: topZone ? 210 * win.uiScale
        : (zone === "mid" ? 190 * win.uiScale : (screen.height - barPad) * 0.2 - 8 * win.uiScale)

    readonly property bool active: name === "gaming" || name === "work"
        ? SideMenuService.open === name
        : (name === "island" ? SideMenuService.islandOpen : SideMenuService.musicOpen)

    visible: {
        if (name === "gaming") return SettingsService.flag("side.gaming") && SettingsService.flag("side.hotspots")
        if (name === "work") return SettingsService.flag("side.work") && SettingsService.flag("side.hotspots")
        if (name === "island") return SettingsService.flag("side.island")
        if (name === "music") return SettingsService.flag("side.music")
        return false
    }

    property bool waitingSecond: false

    MouseArea {
        id: ma
        x: 0
        y: Math.round(win.zoneTop)
        width: parent.width
        height: Math.round(win.zoneH)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (win.waitingSecond) {
                win.waitingSecond = false
                secondTap.stop()
                win.fire()
            } else {
                win.waitingSecond = true
                secondTap.restart()
                pulseAnim.restart()
            }
        }
    }

    function fire() {
        if (name === "gaming" || name === "work")
            SideMenuService.toggle(name)
        else if (name === "island")
            SideMenuService.toggleIsland()
        else if (name === "music")
            SideMenuService.toggleMusic()
    }

    Timer {
        id: secondTap
        interval: 420
        onTriggered: win.waitingSecond = false
    }

    Rectangle {
        id: line
        x: 0
        y: Math.round(win.zoneTop)
        width: 2 * win.uiScale
        height: Math.round(win.zoneH)
        color: mt.nbAccent
        opacity: win.active ? 0.85 : (win.waitingSecond ? 1.0 : (ma.containsMouse ? 0.45 : 0.12))
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        SequentialAnimation {
            id: pulseAnim
            NumberAnimation { target: line; property: "opacity"; to: 1.0; duration: 90 }
            NumberAnimation { target: line; property: "opacity"; to: 0.35; duration: 110 }
            NumberAnimation { target: line; property: "opacity"; to: 1.0; duration: 90 }
        }
    }
}