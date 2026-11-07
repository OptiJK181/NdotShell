import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Quick Panel tile for screen recorder
Item {
    id: root
    width: 180
    height: 180
    property alias recording: service.recording
    property alias duration: service.duration

    readonly property var service: ScreenRecorderService

    Column {
        anchors.centerIn: parent
        spacing: 12

        // Main button
        MouseArea {
            id: mainBtn
            width: 120
            height: 120
            hoverEnabled: true
            cursorShape: root.recording ? Qt.ForbiddenCursor : Qt.PointingHandCursor

            Rectangle {
                anchors.fill: parent
                radius: 60
                color: root.recording ? mt.warnFill : mt.pSurface
                border.width: 2
                border.color: root.recording ? mt.warnFill : mt.pLine
                antialiasing: true

                // Pulsing animation when recording
                SequentialAnimation on opacity {
                    running: root.recording
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.6; duration: 800; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutQuad }
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    name: root.recording ? "stop" : "videocam"
                    size: 40
                    color: root.recording ? mt.pSurface : mt.pInk
                }
            }

            onClicked: {
                if (root.recording) service.stop()
                else service.startScreen()
            }
        }

        // Duration / status
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.recording ? formatDuration(service.duration) : qsTr("Grabar pantalla")
            color: root.recording ? mt.warnFill : mt.pInk
            font.family: mt.fontFamily
            font.pixelSize: root.recording ? 28 : 16
            font.weight: root.recording ? Font.ExtraBold : Font.DemiBold
        }

        // Sub-actions (only when not recording)
        Row {
            visible: !root.recording
            spacing: 8
            IconAction {
                icon: "crop_landscape"
                label: qsTr("Ventana")
                onActivated: service.startWindow()
            }
            IconAction {
                icon: "crop_free"
                label: qsTr("Región")
                onActivated: service.startRegion()
            }
            IconAction {
                icon: "mic_off"
                label: qsTr("Sin audio")
                onActivated: service.startScreenNoAudio()
            }
        }

        // Stop button (when recording)
        Item {
            visible: root.recording
            height: 44
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: service.stop()
                Rectangle {
                    anchors.centerIn: parent
                    width: 100
                    height: 36
                    radius: 18
                    color: mt.warnFill
                    border.width: 1
                    border.color: mt.pLine
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Detener")
                        color: mt.pSurface
                        font.family: mt.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    function formatDuration(sec) {
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }
}

// Small icon action button
Component {
    id: IconAction
    Item {
        width: 56
        height: 56
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: onActivated()
            Rectangle {
                anchors.centerIn: parent
                width: 48
                height: 48
                radius: 24
                color: mt.pSurface
                border.width: 1
                border.color: mt.pLine
                MaterialIcon {
                    anchors.centerIn: parent
                    name: icon
                    size: 22
                    color: mt.pInk
                }
            }
            ToolTip {
                text: label
                delay: 500
            }
        }
    }
}