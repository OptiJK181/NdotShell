import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common

// The corner hotspot: a thin strip ONLY in the top corner of the screen
// (not the whole edge — the rest of the edge stays clickable). It exists
// so the drawers can be opened with a double tap on the corner:
//   first tap  → the accent line pulses (the edge answers)
//   second tap (≤ 420 ms) → the drawer toggles
// The strip is tiny on purpose: outside it, every click reaches your
// windows like normal.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    // "gaming" (right edge) | "work" (left edge)
    property string name: "gaming"
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)
    readonly property bool atRight: name === "gaming"

    anchors { top: true; right: win.atRight; left: !win.atRight }
    // corner only: 8 px wide, ~200 px tall, starts UNDER the top bar so it
    // never blocks the bar's own keys (Quickshell anchors have no topMargin:
    // the pad goes on the children)
    implicitWidth: Math.round(8 * win.uiScale)
    implicitHeight: Math.round(210 * win.uiScale)
    readonly property real topPad: SettingsService.flag("bar.visible")
        ? BarPositionService.thicknessFor("top") : 0
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay

    readonly property bool active: SideMenuService.open === name

    visible: SettingsService.flag(name === "gaming" ? "side.gaming" : "side.work")
        && SettingsService.flag("side.hotspots")

    // first tap: the edge pulses and waits; second tap: drawer toggles
    property bool waitingSecond: false

    MouseArea {
        id: ma
        x: 0
        y: Math.round(win.topPad)
        width: parent.width
        height: parent.height - Math.round(win.topPad)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (win.waitingSecond) {
                win.waitingSecond = false
                secondTap.stop()
                SideMenuService.toggle(win.name)
            } else {
                win.waitingSecond = true
                secondTap.restart()
                pulseAnim.restart()
            }
        }
    }

    Timer {
        id: secondTap
        interval: 420
        onTriggered: win.waitingSecond = false
    }

    // The affordance: a 2 px accent line. Idle = a faint 12% hint that the
    // corner opens something; first tap = it pulses bright; drawer open = it
    // stays lit at 85%.
    Rectangle {
        id: line
        x: 0
        y: Math.round(win.topPad)
        width: 2 * win.uiScale
        height: parent.height - Math.round(win.topPad)
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