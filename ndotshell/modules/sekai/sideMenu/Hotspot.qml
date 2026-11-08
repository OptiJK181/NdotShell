import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common

// Edge hotspots (double-tap): the window is full-edge, but its INPUT MASK
// is only the zone strip — así dan entrada en su franja y NUNCA se comen
// clics del resto (barra, ventanas, widgets). Taponcito de 10 px:
//   1er toque → pulsa la línea de acento
//   2º toque (≤420 ms) → abre su panel
// Zonas: gaming (corner sup-der) · work (corner sup-izq) · island (mid der)
// · music (bottom inf-der).
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    // "gaming" | "work" | "island" | "music"
    property string name: "gaming"
    // "corner" (superior 210 px) | "mid" (derecha, centrado) | "bottom" (inferior 210 px)
    property string zone: "corner"
    readonly property bool atRight: name !== "work"

    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)
    readonly property bool topZone: zone === "corner"
    readonly property real barPad: SettingsService.flag("bar.visible")
        ? BarPositionService.thicknessFor("top") : 0

    // window EXACTO a la franja (sin mask): input solo donde se ve
    anchors { bottom: zone !== "corner"; top: topZone; right: atRight; left: !atRight }
    // sin esto, Quickshell pinta el fondo de la window BLANCO
    color: "transparent"
    implicitWidth: Math.round(10 * win.uiScale)
    implicitHeight: Math.round(zoneH * win.uiScale)
    // posición vertical de la zona: corner arriba (bajo barra), mid al
    // 42% de la pantalla, music abajo
    readonly property real zoneTop: topZone ? barPad
        : (zone === "mid" ? screen.height * 0.42
                          : screen.height - barPad - zoneH)

    // geometría de la zona
    readonly property real zoneH: topZone ? 210 * win.uiScale
        : (zone === "mid" ? 190 * win.uiScale : 210 * win.uiScale)

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

    // la entrada vive SOLO en la franja (mask) — el resto del window es
    // transparente y deja pasar todo
    mask: Region { item: ma }

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