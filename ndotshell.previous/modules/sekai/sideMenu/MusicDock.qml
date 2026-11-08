import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Music dock — full height en el lado derecho (patrón Bar), card abajo.
// Doble toque en la esquina inferior derecha lo abre.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    anchors { top: true; bottom: true; right: true }
    implicitWidth: Math.round(cardW * win.uiScale)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    readonly property real cardW: 340

    property real openAnim: SideMenuService.musicOpen ? 1 : 0
    Behavior on openAnim {
        NumberAnimation {
            duration: 640
            easing.type: Easing.OutElastic
            easing.amplitude: 1.25
            easing.period: 0.5
        }
    }

    visible: SettingsService.flag("side.music")
        && (SideMenuService.musicOpen || win.openAnim > 0.001)
    WlrLayershell.layer: WlrLayer.Top

    mask: Region { item: card }

    Item {
        id: card

        x: 0
        y: Math.round(parent.height * 0.50)
        width: Math.round(parent.width)
        height: Math.round(parent.height * 0.46)

        HoverHandler { id: cardHover }

        Keys.onEscapePressed: SideMenuService.musicOpen = false

        // slab
        Rectangle {
            anchors.fill: parent
            radius: 24 * win.uiScale
            color: mt.nbSurface
            border.width: 1
            border.color: mt.nbBorder
        }

        // accent hairline
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2 * win.uiScale
            color: mt.nbAccent
            opacity: win.openAnim
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20 * win.uiScale
            anchors.rightMargin: 22 * win.uiScale
            spacing: 14 * win.uiScale

            // header
            Item {
                width: parent.width
                height: 44 * win.uiScale

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Text {
                        text: qsTr("MÚSICA")
                        color: mt.nbInk
                        font.family: mt.fontDisplay
                        font.pixelSize: 26 * win.uiScale
                        font.letterSpacing: 7 * win.uiScale
                    }

                    Text {
                        text: qsTr("DOCK DE MEDIOS")
                        color: mt.nbInkSub
                        font.family: mt.fontDisplay
                        font.pixelSize: 9 * win.uiScale
                        font.letterSpacing: 3 * win.uiScale
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
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
                        onClicked: SideMenuService.musicOpen = false
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: mt.nbBorder }

            // vinilo + texto
            Row {
                width: parent.width
                spacing: 16 * win.uiScale

                Item {
                    width: 100 * win.uiScale
                    height: 100 * win.uiScale
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.width
                        radius: width / 2
                        color: "#101010"
                        border.width: 1
                        border.color: mt.nbBorder

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.72
                            height: width
                            radius: width / 2
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                        }

                        Item {
                            anchors.centerIn: parent
                            width: parent.width * 0.62
                            height: width
                            rotation: spinAngle.angle

                            Image {
                                anchors.fill: parent
                                source: media.artUrl !== "" ? media.artUrl : ""
                                visible: media.artUrl !== ""
                                fillMode: Image.PreserveAspectCrop
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: media.artUrl !== "" ? "transparent" : mt.nbBorder
                                visible: media.artUrl === ""

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    name: "music-note-2"
                                    size: 28 * win.uiScale
                                    color: mt.nbInkSub
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 10 * win.uiScale
                                height: 10 * win.uiScale
                                radius: 5 * win.uiScale
                                color: mt.nbSurface
                                border.width: 1
                                border.color: mt.nbBorder
                            }
                        }
                    }

                    Item {
                        id: spinAngle
                        property real angle: 0
                        anchors.fill: parent
                        rotation: angle

                        Timer {
                            interval: 30
                            running: media.playing && parent.visible
                            repeat: true
                            onTriggered: spinAngle.angle = (spinAngle.angle + 2.6) % 360
                        }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 100 * win.uiScale - 16 * win.uiScale
                    spacing: 4 * win.uiScale

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        text: media.playing ? media.title : qsTr("Nothing playing")
                        color: mt.nbInk
                        font.family: mt.fontDisplay
                        font.pixelSize: 16 * win.uiScale
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        visible: media.playing
                        text: media.artist
                        color: mt.nbInkSub
                        font.pixelSize: 12 * win.uiScale
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: mt.nbBorder }

            // transporte
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18 * win.uiScale

                MusicKey { icon: "skip-previous"; onClicked: media.previous() }

                MusicKey {
                    size: 60
                    icon: media.playing ? "pause" : "play"
                    accent: media.playing
                    onClicked: media.togglePlaying()
                }

                MusicKey { icon: "skip-next"; onClicked: media.next() }
            }

            // volumen
            Row {
                visible: media.volumeAvailable
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10 * win.uiScale

                MusicKey {
                    size: 32
                    icon: "volume-cross"
                    onClicked: media.changeVolume(-1)
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 140 * win.uiScale
                    height: 6 * win.uiScale
                    radius: 3 * win.uiScale
                    color: mt.nbBorder

                    Rectangle {
                        width: parent.width * Math.min(1, Math.max(0, (media.player?.volume ?? 0)))
                        height: parent.height
                        radius: 3 * win.uiScale
                        color: mt.nbInkSub
                        Behavior on width { NumberAnimation { duration: 160 } }
                    }
                }

                MusicKey {
                    size: 32
                    icon: "volume-loud"
                    onClicked: media.changeVolume(1)
                }
            }
        }
    }

    MediaSource { id: media }

    component MusicKey: Rectangle {
        property string icon: ""
        property bool accent: false
        property int size: 46
        signal clicked()

        width: size * win.uiScale
        height: size * win.uiScale
        radius: width / 2
        color: keyMa.pressed ? mt.nbBorder : (accent ? mt.nbAccent : mt.nbRaised)
        border.width: 1
        border.color: accent ? mt.nbAccent : mt.nbBorder
        scale: keyMa.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

        MaterialIcon {
            anchors.centerIn: parent
            name: parent.icon
            size: parent.width * 0.42
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