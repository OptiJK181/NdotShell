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
    // Card only: the always-on hotspot (Hotspot.qml in shell.qml) owns the edge.
    implicitWidth: Math.round(cardW * win.uiScale)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property real cardW: 320

    property real slide: SideMenuService.open === "work" ? 1 : 0
    Behavior on slide { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    visible: SideMenuService.open === "work" || win.slide > 0.001
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: SideMenuService.open === "work"
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region { item: card }

    Item {
        id: card

        // From fully hidden (behind the screen's left edge) to fully out.
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

        // Accent hairline on the screen edge (the side touching content).
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2 * win.uiScale
            color: mt.nbAccent
            opacity: win.slide
        }

        Column {
            anchors.fill: parent
            anchors.leftMargin: 22 * win.uiScale
            anchors.rightMargin: 22 * win.uiScale
            anchors.topMargin: 24 * win.uiScale
            anchors.bottomMargin: 18 * win.uiScale
            spacing: 12 * win.uiScale

            // ===== header =====
            Item {
                width: parent.width
                height: 44 * win.uiScale

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Text {
                        text: qsTr("FOCUS")
                        color: mt.nbInk
                        font.family: mt.fontDisplay
                        font.pixelSize: 26 * win.uiScale
                        font.letterSpacing: 7 * win.uiScale
                    }

                    Text {
                        text: qsTr("OFIMÁTICA")
                        color: mt.nbInkSub
                        font.family: mt.fontDisplay
                        font.pixelSize: 9 * win.uiScale
                        font.letterSpacing: 3 * win.uiScale
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: SideMenuService.pinned === "work"
                    width: pinText.implicitWidth + 16 * win.uiScale
                    height: 22 * win.uiScale
                    radius: 11 * win.uiScale
                    color: "transparent"
                    border.width: 1
                    border.color: mt.nbBorder
                    Text {
                        id: pinText
                        anchors.centerIn: parent
                        text: qsTr("FIJADO")
                        color: mt.nbInkSub
                        font.family: mt.fontDisplay
                        font.pixelSize: 9 * win.uiScale
                        font.letterSpacing: 2 * win.uiScale
                    }
                }
            }

            // hairline divider under the header
            Rectangle {
                width: parent.width
                height: 1
                color: mt.nbBorder
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
                onToggled: SettingsService.toggle("focus.enabled")
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

        height: 62 * win.uiScale
        radius: 14 * win.uiScale
        color: tile.on ? Qt.alpha(mt.nbAccent, 0.10) : mt.nbRaised
        border.width: 1
        border.color: tile.on ? mt.nbAccent : mt.nbBorder
        scale: tileMa.pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

        Row {
            anchors.fill: parent
            anchors.margins: 12 * win.uiScale
            spacing: 13 * win.uiScale

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 40 * win.uiScale
                height: 40 * win.uiScale
                radius: 12 * win.uiScale
                color: tile.on ? Qt.alpha(mt.nbAccent, 0.16) : mt.nbSurface
                border.width: 1
                border.color: tile.on ? Qt.alpha(mt.nbAccent, 0.5) : mt.nbBorder

                MaterialIcon {
                    anchors.centerIn: parent
                    name: tile.icon
                    size: 20 * win.uiScale
                    color: tile.on ? mt.nbAccent : mt.nbInk
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 40 * win.uiScale - 13 * win.uiScale - 44 * win.uiScale - 13 * win.uiScale
                spacing: 2
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
            id: tileMa
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.toggled()
        }
    }
}