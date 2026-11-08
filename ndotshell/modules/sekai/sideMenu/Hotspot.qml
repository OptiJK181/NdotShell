import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common

// Edge hotspots (double-tap): full-height windows en cada lado, con
// mask limitando el input a la franja de la zona. Así NUNCA se comen
// clics del resto de la pantalla.
//   gaming  top-right corner  → Gaming drawer
//   work    top-left corner   → Focus drawer
//   island  right edge, mid   → Dynamic Island
//   music   bottom-right corner → Music dock
PanelWindow {
    id: win

    required property var modelData
    // Variants entrega la pantalla directamente (model: Quickshell.screens).
    screen: modelData
    property string name: "gaming"
    property string zone: "corner"
    readonly property bool atRight: name !== "work"

    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)
    readonly property bool topZone: zone === "corner"
    readonly property real barPad: SettingsService.flag("bar.visible")
        ? BarPositionService.thicknessFor("top") : 0

    // full-height en su lado (patrón Bar)
    anchors { top: true; bottom: true; right: atRight; left: !atRight }
    color: "transparent"
    implicitWidth: Math.round(10 * win.uiScale)

    // la zona dentro del window: y + height en coords del window
    readonly property real zoneY: topZone ? barPad
        : (zone === "mid" ? win.height * 0.42
                          : win.height - 210 * win.uiScale)
    readonly property real zoneH: zone === "mid" ? 190 * win.uiScale
                                                  : 210 * win.uiScale

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

    function fire() {
        if (name === "gaming" || name === "work")
            SideMenuService.toggle(name)
        else if (name === "island")
            SideMenuService.toggleIsland()
        else if (name === "music")
            SideMenuService.toggleMusic()
    }

    // input SOLO en la franja — el resto deja pasar todo
    mask: Region { item: zone }

    Item {
        id: zone
        x: 0
        y: Math.round(win.zoneY)
        width: parent.width
        height: Math.round(win.zoneH)

        MouseArea {
            id: ma
            anchors.fill: parent
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
    }

    Timer {
        id: secondTap
        interval: 420
        onTriggered: win.waitingSecond = false
    }

    Rectangle {
        id: line
        x: 0
        y: Math.round(win.zoneY)
        width: 2 * win.uiScale
        height: Math.round(win.zoneH)
        color: mt.nbAccent
        opacity: win.active ? 0.85 : (win.waitingSecond ? 1.0 : (zone.children[0].containsMouse ? 0.45 : 0.12))
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        SequentialAnimation {
            id: pulseAnim
            NumberAnimation { target: line; property: "opacity"; to: 1.0; duration: 90 }
            NumberAnimation { target: line; property: "opacity"; to: 0.35; duration: 110 }
            NumberAnimation { target: line; property: "opacity"; to: 1.0; duration: 90 }
        }
    }
}