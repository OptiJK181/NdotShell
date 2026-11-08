import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// Music dock — la esquina inferior derecha, doble toque la abre.
// Completamente hermoso: vinilo girando con el arte del álbum, título,
// artista y transporte completo, todo en slab Nothing. Gelatinosa al
// abrir (OutElastic). Esc o la ✕ cierran; el toggle de Ajustes
// (side.music) apaga el hotspot y el keybind.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData.screen
    readonly property var mt: Theme.of(screen)
    readonly property real uiScale: ShellScale.forScreen(screen)

    anchors { top: true; bottom: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    implicitWidth: Math.round(cardW * win.uiScale)
    visible: SettingsService.flag("side.music")
        && (SideMenuService.musicOpen || win.openAnim > 0.001)

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

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: SideMenuService.musicOpen
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region { item: card }

    Item {
        id: card

        // de la parte baja (con margen) hasta media pantalla
        // pegada a la esquina inferior derecha; rebote por scale
        x: Math.round(win.width - win.cardW * win.uiScale)
        y: Math.round(parent.height * 0.40)
        width: Math.round(win.cardW * win.uiScale)
        height: Math.round(parent.height * 0.52)
        scale: win.openAnim
        opacity: Math.min(1, win.openAnim * 2)
        transformOrigin: Item.Right

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

        // accent hairline on the screen edge
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

            // ===== header =====
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

            // ===== vinilo + info =====
            Row {
                width: parent.width
                spacing: 16 * win.uiScale

                // vinilo girando con el arte
                Item {
                    width: 110 * win.uiScale
                    height: 110 * win.uiScale
                    anchors.verticalCenter: parent.verticalCenter

                    // disco
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.width
                        radius: width / 2
                        color: "#101010"
                        border.width: 1
                        border.color: mt.nbBorder

                        // surcos
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.72
                            height: width
                            radius: width / 2
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.5
                            height: width
                            radius: width / 2
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                        }

                        // arte del álbum (girando con el disco)
                        Item {
                            anchors.centerIn: parent
                            width: parent.width * 0.62
                            height: width
                            rotation: spin.angle

                            Image {
                                anchors.fill: parent
                                source: media.artUrl !== "" ? media.artUrl : ""
                                visible: media.artUrl !== ""
                                fillMode: Image.PreserveAspectCrop
                                layer.enabled: true
                                layer.effect: null
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: media.artUrl !== "" ? "transparent" : mt.nbBorder
                                visible: media.artUrl === ""

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    name: "music-note-2"
                                    size: 30 * win.uiScale
                                    color: mt.nbInkSub
                                }
                            }

                            // agujero del vinilo
                            Rectangle {
                                anchors.centerIn: parent
                                width: 12 * win.uiScale
                                height: 12 * win.uiScale
                                radius: 6 * win.uiScale
                                color: mt.nbSurface
                                border.width: 1
                                border.color: mt.nbBorder
                            }
                        }
                    }

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: media.playing ? 4200 : 0
                        loops: media.playing ? Animation.Infinite : 1
                    }
                    Timer {
                        id: spin
                        property real angle: 0
                        interval: 30
                        running: media.playing
                        repeat: true
                        onTriggered: parent.rotation = (parent.rotation + 2.6) % 360
                    }
                }

                // texto
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 110 * win.uiScale - 16 * win.uiScale
                    spacing: 4 * win.uiScale

                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        text: media.playing ? media.title : qsTr("Nothing playing")
                        color: mt.nbInk
                        font.family: mt.fontDisplay
                        font.pixelSize: 17 * win.uiScale
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

            // ===== transporte =====
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18 * win.uiScale

                DockKey { icon: "skip-previous"; onClicked: media.previous() }

                DockKey {
                    size: 64
                    icon: media.playing ? "pause" : "play"
                    accent: media.playing
                    onClicked: media.togglePlaying()
                }

                DockKey { icon: "skip-next"; onClicked: media.next() }
            }

            // ===== volumen rápido (si el player lo soporta) =====
            Row {
                visible: media.volumeAvailable
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10 * win.uiScale

                DockKey {
                    size: 34
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

                DockKey {
                    size: 34
                    icon: "volume-loud"
                    onClicked: media.changeVolume(1)
                }
            }
        }
    }

    MediaSource { id: media }

    component DockKey: Rectangle {
        property string icon: ""
        property bool accent: false
        property int size: 48
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