import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Work drawer (ofimática) — Caelestia-style: hover the LEFT edge and the
// panel slides out; move away and it slides back. Super + Shift + W pins it.
// 100% productividad: Pomodoro, Focus Mode, y privacidad del portapapeles
// (modo privado + wipe) para cuando compartes pantalla.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    anchors { top: true; bottom: true; left: true }
    implicitWidth: Math.round((cardW + hotW) * win.uiScale)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property real cardW: 320
    readonly property real hotW: 8

    property real slide: SideMenuService.open === "work" ? 1 : 0
    Behavior on slide { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    visible: SideMenuService.open === "work" || win.slide > 0.001
        || hotspot.containsMouse
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: SideMenuService.open === "work"
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region { item: card }

    // ===== edge hotspot (left) =====
    MouseArea {
        id: hotspot
        x: 0
        y: 0
        width: Math.ceil(win.hotW * win.uiScale)
        height: win.height
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: {
            if (containsMouse) SideMenuService.hoverEnter("work")
            else SideMenuService.hoverLeave()
        }
        onClicked: SideMenuService.toggle("work")
    }

    Item {
        id: card

        x: Math.round(-win.cardW * win.uiScale * (1 - win.slide))
        y: 0
        width: Math.round(win.cardW * win.uiScale)
        height: win.height

        HoverHandler { id: cardHover }
        Binding { target: SideMenuService; property: "cardHovered"; value: cardHover.hovered }

        focus: SideMenuService.open === "work"
        Keys.onEscapePressed: SideMenuService.hide()

        Rectangle {
            anchors.fill: parent
            color: mt.nbSurface
            border.width: 1
            border.color: mt.nbBorder
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20 * win.uiScale
            spacing: 14 * win.uiScale

            // ===== header =====
            Item {
                width: parent.width
                height: 40 * win.uiScale

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("FOCUS")
                    color: mt.nbInk
                    font.family: mt.fontDisplay
                    font.pixelSize: 24 * win.uiScale
                    font.letterSpacing: 6 * win.uiScale
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: SideMenuService.pinned === "work" ? "📌" : ""
                    color: mt.nbInkSub
                    font.pixelSize: 13 * win.uiScale
                }
            }

            // ===== Pomodoro =====
            Rectangle {
                width: parent.width
                height: 158 * win.uiScale
                radius: 12 * win.uiScale
                color: mt.nbRaised
                border.width: 1
                border.color: PomodoroService.running || !PomodoroService.idle
                    ? mt.accentCyan : mt.nbBorder

                Column {
                    anchors.centerIn: parent
                    spacing: 8 * win.uiScale

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: PomodoroService.stateLabel
                        color: mt.nbInkSub
                        font.family: mt.fontDisplay
                        font.pixelSize: 12 * win.uiScale
                        font.letterSpacing: 3 * win.uiScale
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: PomodoroService.format()
                        color: mt.nbInk
                        font.family: mt.fontDisplay
                        font.pixelSize: 52 * win.uiScale
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10 * win.uiScale

                        RoundWorkKey {
                            icon: PomodoroService.running ? "pause" : "play_arrow"
                            onClicked: PomodoroService.toggle()
                        }
                        RoundWorkKey {
                            icon: "skip_next"
                            visible: !PomodoroService.idle
                            onClicked: PomodoroService.skip()
                        }
                        RoundWorkKey {
                            icon: "refresh"
                            onClicked: PomodoroService.reset()
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("%1 ciclos hoy · %2 min")
                              .arg(PomodoroService.completedCycles)
                              .arg(Math.floor(PomodoroService.totalWorkTime / 60))
                        color: mt.nbInkSub
                        font.pixelSize: 11 * win.uiScale
                    }
                }
            }

            // ===== Focus Mode =====
            WorkTile {
                width: parent.width
                icon: "center_focus_strong"
                title: qsTr("Focus Mode")
                sub: FocusService.enabled
                    ? qsTr("Los widgets se apartan mientras trabajas")
                    : qsTr("Widgets siempre visibles")
                on: FocusService.enabled
                onToggled: FocusService.toggle()
            }

            // ===== Clipboard privacy =====
            Column {
                width: parent.width
                spacing: 8 * win.uiScale

                Text {
                    text: qsTr("PORTAPAPELES")
                    color: mt.nbInkSub
                    font.family: mt.fontDisplay
                    font.pixelSize: 12 * win.uiScale
                    font.letterSpacing: 4 * win.uiScale
                }

                WorkTile {
                    width: parent.width
                    icon: ClipboardHistoryService.privateMode ? "visibility_off" : "visibility"
                    title: qsTr("Modo privado")
                    sub: ClipboardHistoryService.privateMode
                        ? qsTr("No se graba nada (Super + P)")
                        : qsTr("Grabando · Secretos nunca se guardan")
                    on: ClipboardHistoryService.privateMode
                    onToggled: {
                        const on = ClipboardHistoryService.togglePrivate()
                        OSDSource.showPrivate(on)
                    }
                }

                WorkTile {
                    width: parent.width
                    icon: "delete_sweep"
                    title: qsTr("Borrar historial")
                    sub: qsTr("Limpia todo, fijados incluidos")
                    on: false
                    onToggled: ClipboardHistoryService.wipe()
                }
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: qsTr("Toca el borde izquierdo para abrir · Esc cierra")
                color: mt.nbInkSub
                font.pixelSize: 12 * win.uiScale
            }
        }
    }

    component RoundWorkKey: Rectangle {
        property string icon: ""
        signal clicked()

        width: 44 * win.uiScale
        height: 44 * win.uiScale
        radius: 22 * win.uiScale
        color: keyMa.pressed ? mt.nbBorder : mt.nbSurface
        border.width: 1
        border.color: mt.nbBorder

        MaterialIcon {
            anchors.centerIn: parent
            name: parent.icon
            size: 20 * win.uiScale
            color: mt.nbInk
        }

        MouseArea {
            id: keyMa
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component WorkTile: Rectangle {
        id: tile
        property string icon: ""
        property string title: ""
        property string sub: ""
        property bool on: false
        signal toggled()

        height: 60 * win.uiScale
        radius: 12 * win.uiScale
        color: tile.on ? Qt.alpha(mt.nbAccent, 0.12) : mt.nbRaised
        border.width: 1
        border.color: tile.on ? mt.nbAccent : mt.nbBorder

        Row {
            anchors.fill: parent
            anchors.margins: 12 * win.uiScale
            spacing: 12 * win.uiScale

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: tile.icon
                size: 22 * win.uiScale
                color: tile.on ? mt.nbAccent : mt.nbInk
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 22 * win.uiScale - 12 * win.uiScale - 48 * win.uiScale
                spacing: 1
                Text {
                    text: tile.title
                    color: mt.nbInk
                    font.pixelSize: 15 * win.uiScale
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: tile.sub
                    color: mt.nbInkSub
                    font.pixelSize: 12 * win.uiScale
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 44 * win.uiScale
                height: 24 * win.uiScale
                radius: 12 * win.uiScale
                color: tile.on ? mt.nbAccent : mt.nbSurface
                border.width: 1
                border.color: tile.on ? mt.nbAccent : mt.nbBorder

                Rectangle {
                    x: tile.on ? parent.width - width - 2 * win.uiScale : 2 * win.uiScale
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18 * win.uiScale
                    height: 18 * win.uiScale
                    radius: 9 * win.uiScale
                    color: tile.on ? "#ffffff" : mt.nbInkSub
                    Behavior on x { NumberAnimation { duration: 140 } }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.toggled()
        }
    }
}