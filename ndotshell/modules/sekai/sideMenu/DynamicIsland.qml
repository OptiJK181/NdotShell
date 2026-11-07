import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Dynamic Island — Apple-style top-center pill, Nothing dress:
//   compact: Ndot 55 clock + a red rec dot / cyan pomodoro dot
//   hover (or click to pin): springs open into a wide card with three
//   mini-panels — RELOJ (big numerals), MÚSICA (title + controls),
//   POMODORO (timer + play/skip). Esc or click-away closes.
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
    visible: SettingsService.flag("side.island") || openAnim > 0.001

    // compact(0) → expanded(1)
    property real openAnim: expanded ? 1 : 0
    property bool expanded: false
    Behavior on openAnim { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region { item: pill }

    Item {
        id: pill

        property real compactW: 150
        property real openW: 620
        property real compactH: 40
        property real openH: 150

        anchors.top: parent.top
        anchors.topMargin: Math.round((BarPositionService.thicknessFor("top") + 6) * win.uiScale)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round((compactW + (openW - compactW) * win.openAnim) * win.uiScale)
        height: Math.round((compactH + (openH - compactH) * win.openAnim) * win.uiScale)

        HoverHandler {
            id: hov
            onHoveredChanged: {
                if (hovered) win.expanded = true
                else leaveTimer.restart()
            }
        }
        Timer {
            id: leaveTimer
            interval: 500
            onTriggered: if (!hov.hovered && !pill.islandPin) win.expanded = false
        }
        property bool islandPin: false

        // ===== slab =====
        Rectangle {
            anchors.fill: parent
            radius: Math.round(height / 2)
            color: mt.nbSurface
            border.width: 1
            border.color: mt.nbBorder

            // rec dot glow while recording
            Rectangle {
                visible: ScreenRecorderService.recording
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: mt.nbAccent
            }
        }

        // ===== compact face: clock + status dots =====
        Item {
            anchors.fill: parent
            opacity: 1 - win.openAnim
            visible: opacity > 0.01

            Row {
                anchors.centerIn: parent
                spacing: 8 * win.uiScale

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: ScreenRecorderService.recording
                    width: 8 * win.uiScale
                    height: 8 * win.uiScale
                    radius: 4 * win.uiScale
                    color: mt.nbAccent
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatTime(new Date(), SettingsService.flag("time.use24h") ? "HH:mm" : "h:mm ap").toUpperCase()
                    color: mt.nbInk
                    font.family: mt.fontDisplay
                    font.pixelSize: 18 * win.uiScale
                    font.letterSpacing: 2 * win.uiScale
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: PomodoroService.running
                    width: 8 * win.uiScale
                    height: 8 * win.uiScale
                    radius: 4 * win.uiScale
                    color: mt.accentCyan
                }
            }
        }

        // ===== expanded face =====
        Row {
            anchors.fill: parent
            anchors.margins: 16 * win.uiScale
            spacing: 12 * win.uiScale
            opacity: win.openAnim
            visible: win.openAnim > 0.01

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
                        elide: Text.ElideRight
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
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
                            accent: true
                            onClicked: media.togglePlaying()
                        }
                        IslandKey { icon: "skip-next"; onClicked: media.next() }
                    }
                }
            }

            // POMODORO + REC
            Rectangle {
                width: Math.round((parent.width - 2 * 12 * win.uiScale) * 0.32)
                height: parent.height
                radius: 12 * win.uiScale
                color: mt.nbRaised
                border.width: 1
                border.color: PomodoroService.running ? mt.accentCyan : mt.nbBorder

                Column {
                    anchors.centerIn: parent
                    spacing: 6 * win.uiScale

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: ScreenRecorderService.recording
                            ? "REC " + fmtRec(ScreenRecorderService.duration)
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

        Keys.onEscapePressed: { islandPin = false; win.expanded = false }
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