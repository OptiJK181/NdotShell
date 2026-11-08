import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.sekai.sideMenu

// Work drawer (ofimática) — full height en el lado izquierdo (patrón Bar).
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    anchors { top: true; bottom: true; left: true }
    implicitWidth: Math.round(cardW * win.uiScale)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property real cardW: 330
    readonly property real topPad: SettingsService.flag("bar.visible")
        ? BarPositionService.thicknessFor("top") + 6 : 12

    property real slide: SideMenuService.open === "work"
        && SettingsService.flag("side.work") ? 1 : 0
    Behavior on slide {
        NumberAnimation {
            duration: 640
            easing.type: Easing.OutElastic
            easing.amplitude: 1.3
            easing.period: 0.45
        }
    }

    visible: win.slide > 0.001
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: SideMenuService.open === "work"
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region { item: card }

    // driver de stagger
    Item {
        id: driver
        property real t: SideMenuService.open === "work" ? 1 : 0
        Behavior on t { NumberAnimation { duration: 640; easing.type: Easing.OutCubic } }
        function prog(i) {
            return Math.max(0, Math.min(1, (t - (0.06 + i * 0.07)) / 0.35))
        }
    }

    Item {
        id: card

        x: 0
        y: Math.round(win.topPad)
        width: Math.round(parent.width)
        height: Math.round(parent.height - win.topPad)

        HoverHandler { id: cardHover }

        focus: SideMenuService.open === "work"
        Keys.onEscapePressed: SideMenuService.hide()

        Rectangle {
            anchors.fill: parent
            color: mt.nbSurface
            border.width: 1
            border.color: mt.nbBorder
        }

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
            anchors.topMargin: 20 * win.uiScale
            anchors.bottomMargin: 14 * win.uiScale
            spacing: 8 * win.uiScale

            // header
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

            Rectangle { width: parent.width; height: 1; color: mt.nbBorder }

            // Pomodoro
            Rectangle {
                width: parent.width
                height: 150 * win.uiScale
                radius: 14 * win.uiScale
                color: mt.nbRaised
                border.width: 1
                border.color: PomodoroService.running ? mt.accentCyan : mt.nbBorder

                Column {
                    anchors.centerIn: parent
                    spacing: 6 * win.uiScale

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: PomodoroService.stateLabel
                        color: mt.nbInkSub
                        font.family: mt.fontDisplay
                        font.pixelSize: 11 * win.uiScale
                        font.letterSpacing: 3 * win.uiScale
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: PomodoroService.format()
                        color: mt.nbInk
                        font.family: mt.fontDisplay
                        font.pixelSize: 44 * win.uiScale
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10 * win.uiScale

                        RoundWorkKey {
                            icon: PomodoroService.running ? "pause" : "play"
                            onClicked: PomodoroService.toggle()
                        }
                        RoundWorkKey {
                            icon: "skip-next"
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

            // pulpo
            Rectangle {
                width: parent.width
                height: 68 * win.uiScale
                radius: 14 * win.uiScale
                color: mt.nbRaised
                border.width: 1
                border.color: PomodoroService.running ? mt.accentCyan : mt.nbBorder

                Row {
                    anchors.fill: parent
                    anchors.margins: 10 * win.uiScale
                    spacing: 12 * win.uiScale

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "🐙"
                        font.pixelSize: 28 * win.uiScale

                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            alwaysRunToEnd: true
                            NumberAnimation { to: -3 * win.uiScale; duration: 900; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 3 * win.uiScale; duration: 900; easing.type: Easing.InOutQuad }
                        }

                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            alwaysRunToEnd: true
                            NumberAnimation { to: 1.08; duration: 450; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.0; duration: 450; easing.type: Easing.InOutQuad }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 28 * win.uiScale - 12 * win.uiScale - 16 * win.uiScale
                        spacing: 2 * win.uiScale

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: win.octoShown
                            color: mt.nbInk
                            font.family: mt.fontDisplay
                            font.pixelSize: 13 * win.uiScale
                        }

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: PomodoroService.running
                                ? qsTr("Pomodoro activo — no le pierdas la pista")
                                : qsTr("El pulpo toma notas por ti")
                            color: mt.nbInkSub
                            font.pixelSize: 11 * win.uiScale
                        }
                    }
                }
            }

            // menu
            DrawerMenuItem {
                appear: driver.prog(0)
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                text: qsTr("FOCUS MODE")
                selected: FocusService.enabled
                onActivated: SettingsService.toggle("focus.enabled")
            }

            DrawerMenuItem {
                appear: driver.prog(1)
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                text: qsTr("MODO PRIVADO")
                selected: ClipboardHistoryService.privateMode
                onActivated: {
                    const on = ClipboardHistoryService.togglePrivate()
                    OSDSource.showPrivate(on)
                }
            }

            DrawerMenuItem {
                appear: driver.prog(2)
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                action: true
                text: qsTr("BORRAR HISTORIAL")
                onActivated: ClipboardHistoryService.wipe()
            }

            DrawerMenuItem {
                appear: driver.prog(3)
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                text: qsTr("NOTAS")
                selected: NotesService.shown
                onActivated: NotesService.setShown(!NotesService.shown)
            }

            DrawerMenuItem {
                appear: driver.prog(4)
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                text: qsTr("TO-DO")
                selected: TodoService.shown
                onActivated: TodoService.setShown(!TodoService.shown)
            }

            DrawerMenuItem {
                appear: driver.prog(5)
                s: win.uiScale
                inkColor: mt.nbInk
                subInkColor: mt.nbInkSub
                accentColor: mt.nbAccent
                displayFont: mt.fontDisplay
                text: qsTr("CALENDARIO")
                selected: CalendarCardService.shown
                onActivated: CalendarCardService.setShown(!CalendarCardService.shown)
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: qsTr("Doble toque en la esquina · Esc cierra")
                color: mt.nbInkSub
                font.pixelSize: 11 * win.uiScale
            }
        }
    }

    // pulpo typer
    property string octoFull: ""
    property int octoMsg: 0
    property int octoChars: 0
    readonly property var octoMessages: [
        qsTr("escribiendo tus notas…"),
        qsTr("anotando el pomodoro…"),
        qsTr("armando tu escritorio…"),
        qsTr("tentáculos en el teclado…"),
        qsTr("nada se le escapa al pulpo")
    ]
    readonly property string octoShown: octoMessages[octoMsg].slice(0, octoChars)
        + (octoChars < octoMessages[octoMsg].length && octoChars % 2 === 0 ? "▌" : "")

    Timer {
        interval: 62
        running: win.slide > 0.9
        repeat: true
        onTriggered: {
            const full = win.octoMessages[win.octoMsg]
            if (win.octoChars < full.length) {
                win.octoChars++
            } else {
                octoHold.restart()
            }
        }
    }

    Timer {
        id: octoHold
        interval: 1600
        onTriggered: {
            win.octoMsg = (win.octoMsg + 1) % win.octoMessages.length
            win.octoChars = 0
        }
    }

    component RoundWorkKey: Rectangle {
        property string icon: ""
        signal clicked()

        width: 40 * win.uiScale
        height: 40 * win.uiScale
        radius: 20 * win.uiScale
        color: keyMa.pressed ? mt.nbBorder : mt.nbSurface
        border.width: 1
        border.color: mt.nbBorder

        MaterialIcon {
            anchors.centerIn: parent
            name: parent.icon
            size: 18 * win.uiScale
            color: mt.nbInk
        }

        MouseArea {
            id: keyMa
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}