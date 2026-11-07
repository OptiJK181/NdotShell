import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Dynamic Island — Apple-style, Nothing dress. NOT manual: the pill is
// hidden until something has something to say, and a hover zone under the
// bar springs it open any time.
//   auto-visible (compact) while: recording · pomodoro running · music playing
//   hidden otherwise — the top-center hover zone (hover zone) opens it
//   click the zone/pill → pin; Esc or moving away closes
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    // something to say → the pill shows by itself
    readonly property bool autoVisible: ScreenRecorderService.recording
        || PomodoroService.running || media.playing
    // open (expanded) = pinned, or the pointer is on the zone/pill
    property bool expanded: false
    property bool pinned: false
    readonly property bool shown: (expanded || autoVisible)
        && SettingsService.flag("side.island")

    anchors { top: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitHeight: Math.round(210 * win.uiScale)
    visible: win.shown || win.openAnim > 0.001

    property real openAnim: expanded ? 1 : 0
    Behavior on openAnim {
        NumberAnimation {
            duration: 560
            easing.type: Easing.OutElastic
            easing.amplitude: 1.35
            easing.period: 0.45
        }
    }

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
                if (hovered) {
                    win.expanded = true
                    leaveTimer.restart()
                }
            }
        }

        Timer {
            id: leaveTimer
            interval: 600
            onTriggered: {
                if (!hov.hovered && !win.pinned)
                    win.expanded = false
            }
        }

        Keys.onEscapePressed: {
            win.pinned = false
            win.expanded = false
        }

        // slab
        Rectangle {
            anchors.fill: parent
            radius: Math.round(height / 2)
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

                    Timer { interval: 1000; running: true; repeat: true
                            onTriggered: parent.text = Qt.formatTime(new Date(), SettingsService.flag("time.use24h") ? "HH:mm" : "h:mm ap").toUpperCase() }
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

    // ===== hover zone: a slim strip under the bar, always mapped while the
    // island is enabled. Hover springs the island open even when hidden.
    PanelWindow {
        id: zone
        screen: win.screen
        anchors { top: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        implicitHeight: Math.round(34 * win.uiScale)
        visible: SettingsService.flag("side.island") && !win.pinned
        WlrLayershell.layer: WlrLayer.Overlay

        MouseArea {
            id: zoneMa
            anchors.fill: parent
            anchors.leftMargin: 320 * win.uiScale
            anchors.rightMargin: 320 * win.uiScale
            anchors.topMargin: Math.round(BarPositionService.thicknessFor("top") * 0.5)
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: {
                if (containsMouse) win.expanded = true
                else leaveTimer.restart()
            }
            onClicked: {
                win.pinned = !win.pinned
                win.expanded = win.pinned
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