import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "../../common/functions/LyricsMath.js" as LM

// Music dock — full height en el lado derecho (patrón Bar), card abajo.
// Doble toque en la esquina inferior derecha lo abre.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData
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

    // ===== posición y letra =====
    // Players announce position unevenly; it is read twice a second (same
    // recipe as NowPlayingWidget) and the lane smooths the steps. The lyric
    // line rides the same clock with the service's sync offset.
    property real elapsed: 0
    property real trackLength: 0
    readonly property bool seekable: media.player !== null && media.player.canSeek
        && media.player.positionSupported === true && win.trackLength > 0

    function readPosition(): void {
        const p = media.player
        if (!p) {
            win.elapsed = 0
            win.trackLength = 0
            return
        }
        win.trackLength = p.lengthSupported ? Math.max(0, Number(p.length) || 0) : 0
        if (!p.positionSupported) {
            win.elapsed = 0
            return
        }
        p.positionChanged()
        win.elapsed = Math.max(0, Number(p.position) || 0)
    }

    function seekTo(fraction): void {
        if (!win.seekable)
            return
        const f = Math.max(0, Math.min(1, Number(fraction) || 0))
        const target = f * win.trackLength
        media.player.positionChanged()
        media.player.position = target
        win.elapsed = target
    }

    Timer {
        interval: 500
        repeat: true
        triggeredOnStart: true
        running: win.visible && media.present
        onTriggered: win.readPosition()
    }

    readonly property var lyLines: LyricsService.lines
    readonly property int lyIndex: LM.lineIndexAt(win.lyLines, win.elapsed + LyricsService.syncTotal)
    readonly property string lyLine: {
        if (!media.playing || win.lyLines.length === 0) return ""
        const l = win.lyLines[win.lyIndex]
        return l && l.text ? l.text : ""
    }
    readonly property string lyNext: {
        if (!media.playing || win.lyLines.length === 0) return ""
        const l = win.lyLines[win.lyIndex + 1]
        return l && l.text ? l.text : ""
    }

    function fmtTime(sec) {
        sec = Math.max(0, Math.floor(Number(sec) || 0))
        const m = Math.floor(sec / 60)
        const s = sec % 60
        return m + ":" + ("0" + s).slice(-2)
    }

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
            spacing: 10 * win.uiScale

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
                    width: 92 * win.uiScale
                    height: 92 * win.uiScale
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
                    width: parent.width - 92 * win.uiScale - 16 * win.uiScale
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

            // ===== la pista: barra fina, punto rojo y los dos tiempos =====
            Item {
                width: parent.width
                height: 26 * win.uiScale
                visible: media.present

                Item {
                    id: laneTrack
                    x: 0
                    y: 4 * win.uiScale
                    width: parent.width
                    height: 4 * win.uiScale

                    Rectangle {
                        anchors.fill: parent
                        radius: 2 * win.uiScale
                        color: mt.nbBorder
                    }

                    Rectangle {
                        width: parent.width * (win.trackLength > 0 ? Math.min(1, win.elapsed / win.trackLength) : 0)
                        height: parent.height
                        radius: 2 * win.uiScale
                        color: mt.nbAccent

                        Behavior on width { NumberAnimation { duration: 460; easing.type: Easing.Linear } }
                    }

                    Rectangle {
                        visible: win.seekable
                        width: 8 * win.uiScale
                        height: 8 * win.uiScale
                        radius: 4 * win.uiScale
                        y: -2 * win.uiScale
                        color: mt.nbAccent
                        x: Math.max(0, Math.min(laneTrack.width - width,
                            laneTrack.width * (win.trackLength > 0 ? Math.min(1, win.elapsed / win.trackLength) : 0) - width / 2))

                        Behavior on x { NumberAnimation { duration: 460; easing.type: Easing.Linear } }
                    }
                }

                Text {
                    anchors.top: laneTrack.bottom
                    anchors.topMargin: 3 * win.uiScale
                    text: win.fmtTime(win.elapsed / 1000)
                    color: mt.nbInkSub
                    font.family: mt.fontDisplay
                    font.pixelSize: 10 * win.uiScale
                }

                Text {
                    anchors.top: laneTrack.bottom
                    anchors.topMargin: 3 * win.uiScale
                    anchors.right: parent.right
                    text: win.fmtTime(win.trackLength / 1000)
                    visible: win.trackLength > 0
                    color: mt.nbInkSub
                    font.family: mt.fontDisplay
                    font.pixelSize: 10 * win.uiScale
                }

                MouseArea {
                    enabled: win.seekable
                    anchors.fill: parent
                    anchors.topMargin: -4 * win.uiScale
                    hoverEnabled: true
                    cursorShape: win.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
                    preventStealing: true

                    function fracAt(mx) {
                        return Math.max(0, Math.min(1, mx / Math.max(1, laneTrack.width)))
                    }

                    onClicked: mouse => win.seekTo(fracAt(mouse.x))
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

            Rectangle { width: parent.width; height: 1; color: mt.nbBorder }

            // ===== la letra: la línea que suena, y la que viene =====
            Column {
                width: parent.width
                visible: win.lyLine !== ""
                spacing: 3 * win.uiScale

                Text {
                    text: qsTr("LETRA")
                    color: mt.nbInkSub
                    font.family: mt.fontDisplay
                    font.pixelSize: 9 * win.uiScale
                    font.letterSpacing: 3 * win.uiScale
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    text: win.lyLine
                    color: mt.nbInk
                    font.family: mt.fontDisplay
                    font.pixelSize: 14 * win.uiScale
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    visible: win.lyNext !== ""
                    elide: Text.ElideRight
                    text: win.lyNext
                    color: mt.nbInkSub
                    opacity: 0.7
                    font.pixelSize: 11 * win.uiScale
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