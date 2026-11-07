import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Pomodoro Timer Widget
Item {
    id: root
    width: 280
    height: 200
    property alias state: service.state
    property alias timeLeft: service.timeLeft
    property alias format: service.format

    readonly property var service: PomodoroService

    Column {
        anchors.centerIn: parent
        spacing: 16

        // State label
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: service.stateLabel
            color: service.state === PomodoroService.Work ? mt.accentCyan
                     : service.state === PomodoroService.Break ? "#4ade80"
                     : service.state === PomodoroService.LongBreak ? "#60a5fa"
                     : mt.pInkSub
            font.family: mt.fontFamily
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }

        // Big timer
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: service.format()
            color: mt.pInk
            font.family: mt.fontFamily
            font.pixelSize: 64
            font.weight: Font.ExtraBold
        }

        // Progress ring
        Item {
            width: 140
            height: 140
            anchors.horizontalCenter: parent.horizontalCenter

            Canvas {
                id: ring
                anchors.fill: parent
                property real progress: service.state === PomodoroService.Idle ? 0
                              : 1 - service.timeLeft / (service.state === PomodoroService.Work ? service.workDuration
                                 : service.state === PomodoroService.Break ? service.breakDuration
                                 : service.longBreakDuration)
                onProgressChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var cx = width / 2, cy = height / 2, r = 60
                    // Background
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                    ctx.strokeStyle = mt.pLine
                    ctx.lineWidth = 8
                    ctx.stroke()
                    // Progress
                    if (progress > 0) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * progress)
                        ctx.strokeStyle = (service.state === PomodoroService.Work ? "#00ffff"
                                        : service.state === PomodoroService.Break ? "#4ade80"
                                        : "#60a5fa")
                        ctx.lineWidth = 8
                        ctx.lineCap = "round"
                        ctx.stroke()
                    }
                }
            }

            // Cycle count
            Text {
                anchors.centerIn: parent
                text: qsTr("%1 ciclos").arg(service.completedCycles)
                color: mt.pInkSub
                font.family: mt.fontFamily
                font.pixelSize: 14
            }
        }

        // Controls
        Row {
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter

            // Main button
            MouseArea {
                id: mainBtn
                width: 80
                height: 80
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: service.toggle()
                Rectangle {
                    anchors.fill: parent
                    radius: 40
                    color: service.state === PomodoroService.Idle ? mt.accentCyan
                             : timer.running ? mt.warnFill : "#ffa500"
                    border.width: 2
                    border.color: mt.pLine
                    antialiasing: true
                    MaterialIcon {
                        anchors.centerIn: parent
                        name: service.state === PomodoroService.Idle ? "play_arrow"
                                 : timer.running ? "pause" : "play_arrow"
                        size: 32
                        color: mt.pSurface
                    }
                }
            }

            // Reset
            IconAction {
                icon: "refresh"
                onActivated: service.reset()
            }

            // Skip
            IconAction {
                icon: "skip_next"
                onActivated: service.skip()
                visible: service.state !== PomodoroService.Idle
            }
        }
    }

    Timer {
        id: timer
        interval: 100
        running: true
        onTriggered: ring.requestPaint()
    }
}

Component {
    id: IconAction
    MouseArea {
        width: 48
        height: 48
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: onActivated()
        Rectangle {
            anchors.centerIn: parent
            width: 40
            height: 40
            radius: 20
            color: mt.pSurface
            border.width: 1
            border.color: mt.pLine
            MaterialIcon {
                anchors.centerIn: parent
                name: icon
                size: 20
                color: mt.pInk
            }
        }
    }
}