import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common

// The edge hotspot (double-tap the corner): a thin transparent strip down
// one screen edge. First tap flashes a 2 px accent line (the edge answers);
// a second tap within 420 ms toggles the matching drawer. Clicks pass
// through (NoButton); the strip never eats input.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    // "gaming" (right edge) | "work" (left edge)
    property string name: "gaming"
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)
    readonly property bool atRight: name === "gaming"

    anchors { top: true; bottom: true; right: win.atRight; left: !win.atRight }
    implicitWidth: Math.round(10 * win.uiScale)
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
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
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
    // edge opens something; first tap = it pulses bright; drawer open = it
    // stays lit at 85%.
    Rectangle {
        id: line
        anchors { top: parent.top; bottom: parent.bottom; right: win.atRight && parent.right; left: !win.atRight && parent.left }
        width: 2 * win.uiScale
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