import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Dynamic Island — 100% MANUAL: no aparece hasta que la actives
// (Super + Shift + D, o `ipc call island toggle`). Se dibuja como tarjeta
// de tres paneles bajo la barra (RELOJ · MÚSICA · POMODORO/REC), con
// salida gelatinosa. Esc, la ✕ o el keybind la cierran. El toggle de
// Ajustes (side.island) apaga también el keybind.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    anchors { top: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitHeight: Math.round(200 * win.uiScale)
    visible: SideMenuService.islandOn && SideMenuService.islandOpen

    property real openAnim: SideMenuService.islandOpen ? 1 : 0
    Behavior on openAnim {
        NumberAnimation {
            duration: 620
            easing.type: Easing.OutElastic
            easing.amplitude: 1.3
            easing.period: 0.45
        }
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: SideMenuService.islandOpen
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region { item: card }

    Item {
        id: card

        property real openH: 150

        anchors.top: parent.top
        anchors.topMargin: Math.round((SettingsService.flag("bar.visible")
            ? BarPositionService.thicknessFor("top") + 6 : 6) * win.uiScale)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round(620 * win.uiScale)
        height: Math.round(openH * win.uiScale * Math.min(1, win.openAnim * 1.2))
        opacity: win.openAnim
        scale: win.openAnim
        transformOrigin: Item.Top

        Keys.onEscapePressed: SideMenuService.islandOpen = false

        // slab
        Rectangle {
            anchors.fill: parent
            radius: 20 * win.uiScale
            color: mt.nbSurface
            border.width: 1
            border.color: mt.nbBorder

            Rectangle {
                visible: ScreenRecorderService.recording
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: mt.nbAccent
            }
        }

        // ✕ close
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10 * win.uiScale
            width: 26 * win.uiScale
            height: 26 * win.uiScale
            radius: 13 * win.uiScale
            color: xMa.pressed ? mt.nbBorder : mt.nbSurface
            border.width: 1
            border.color: mt.nbBorder

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: mt.nbInk
                font.pixelSize: 12 * win.uiScale
            }

            MouseArea {
                id: xMa
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: SideMenuService.islandOpen = false
            }
        }

        Row {
            anchors.fill: parent
            anchors.margins: 16 * win.uiScale
            anchors.rightMargin: 40 * win.uiScale
            spacing: 12 * win.uiScale

            // RELOJ
            Rectangle {
                width: Math.round((parent.width - 2 * 12 * win.uiScale) * 0.32)
                height: parent.height
                radius: 12 * win.uiScale
                color: mt.nbRaised
                border.width: 1
                border.color: mt.nbBorder

                Column {
                    anchors.centerIn: parent
                    spacing: 2 * win.uiScale

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        property var d: new Date()
                        text: Qt.formatTime(d, SettingsService.flag("time.use24h") ? "HH:mm" : "h:mm")
                        color: mt.nbInk
                        font.family: mt.fontDisplay
                        font.pixelSize: 30 * win.uiScale

                        Timer { interval: 1000; running: true; repeat: true
                                onTriggered: parent.d = new Date() }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(new Date(), "ddd d MMM").toUpperCase()
                        color: mt.nbInkSub
                        font.family: mt.fontDisplay
                        font.pixelSize: 9 * win.uiScale
                        font.letterSpacing: 2 * win.uiScale
                    }
                }
            }

            // MÚSICA
            Rectangle {
                width: Math.round((parent.width - 2 * 12 * win.uiScale) * 0.36)
                height: parent.height
                radius: 12 * win.uiScale
                color: mt.nbRaised
                border.width: 1
                border.color: mt.nbBorder

                Column {
                    anchors.centerIn: parent
                    spacing: 6 * win.uiScale
                    width: parent.width - 16 * win.uiScale

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: media.playing ? media.title : qsTr("Nothing playing")
                        color: mt.nbInk
                        font.family: mt.fontDisplay
                        font.pixelSize: 13 * win.uiScale
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        visible: media.playing
                        text: media.artist
                        color: mt.nbInkSub
                        font.pixelSize: 10 * win.uiScale
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 14 * win.uiScale

                        IslandKey { icon: "skip-previous"; onClicked: media.previous() }
                        IslandKey {
                            icon: media.playing ? "pause" : "play"
                            accent: media.playing
                            onClicked: media.togglePlaying()
                        }
                        IslandKey { icon: "skip-next"; onClicked: media.next() }
                    }
                }
            }

            // POMODORO / REC
            Rectangle {
                width: Math.round((parent.width - 2 * 12 * win.uiScale) * 0.32)
                height: parent.height
                radius: 12 * win.uiScale
                color: mt.nbRaised
                border.width: 1
                border.color: PomodoroService.running ? mt.accentCyan
                    : ScreenRecorderService.recording ? mt.nbAccent : mt.nbBorder

                Column {
                    anchors.centerIn: parent
                    spacing: 6 * win.uiScale

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: ScreenRecorderService.recording
                            ? "REC " + win.fmtRec(ScreenRecorderService.duration)
                            : PomodoroService.format()
                        color: ScreenRecorderService.recording ? mt.nbAccent : mt.nbInk
                        font.family: mt.fontDisplay
                        font.pixelSize: 22 * win.uiScale
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10 * win.uiScale

                        IslandKey {
                            icon: PomodoroService.running ? "pause" : "play"
                            onClicked: PomodoroService.toggle()
                        }
                        IslandKey {
                            icon: "videocam"
                            accent: ScreenRecorderService.recording
                            onClicked: ScreenRecorderService.toggle()
                        }
                    }
                }
            }
        }
    }

    MediaSource { id: media }

    function fmtRec(sec) {
        const m = Math.floor(sec / 60)
        const s = sec % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    component IslandKey: Rectangle {
        property string icon: ""
        property bool accent: false
        signal clicked()

        width: 34 * win.uiScale
        height: 34 * win.uiScale
        radius: 17 * win.uiScale
        color: keyMa.pressed ? mt.nbBorder : (accent ? mt.nbAccent : mt.nbSurface)
        border.width: 1
        border.color: accent ? mt.nbAccent : mt.nbBorder

        MaterialIcon {
            anchors.centerIn: parent
            name: parent.icon
            size: 16 * win.uiScale
            color: parent.accent ? "#ffffff" : mt.nbInk
        }

        MouseArea {
            id: keyMa
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}