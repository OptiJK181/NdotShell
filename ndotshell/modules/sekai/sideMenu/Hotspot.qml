import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common

// The always-on edge hotspot (Caelestia-style): a thin transparent strip
// down one screen edge. Hover it and the matching drawer slides out; the
// strip also lights up with a 2 px accent line so the edge says "I open
// something". Clicks pass through (NoButton); a tap still opens.
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
    implicitWidth: Math.round(8 * win.uiScale)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay

    readonly property bool active: SideMenuService.open === name
    readonly property bool armed: ma.containsMouse && !active

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: {
            if (containsMouse) SideMenuService.hoverEnter(win.name)
            else SideMenuService.hoverLeave()
        }
        onClicked: SideMenuService.toggle(win.name)
    }

    // The affordance: a 2 px accent line that fades in when the pointer
    // touches the edge (and out once the drawer is open).
    Rectangle {
        anchors { top: parent.top; bottom: parent.bottom; right: win.atRight && parent.right; left: !win.atRight && parent.left }
        width: 2 * win.uiScale
        color: mt.nbAccent
        opacity: win.armed ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }
}