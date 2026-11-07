pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen recorder using wf-recorder (Wayland)
// Provides: start(), stop(), toggle(), recording property, file path
Singleton {
    id: root

    property bool recording: false
    property string lastFile: ""
    property string status: "idle"   // idle, recording, encoding, error
    property int duration: 0        // seconds while recording

    property string saveDir: ""
    readonly property string wfRecorder: "wf-recorder"

    Component.onCompleted: {
        // Construct path without FileSystem (import is blackholed)
        var homeDir = String(Qt.resolvedUrl("../..")).replace("file://", "");
        root.saveDir = homeDir + "/download/ScreenRecordings";
    }

    // Start recording
    // mode: "screen" (full), "window" (select), "region" (slurp)
    // audio: true/false
    function start(mode, audio) {
        if (root.recording) return
        root.status = "recording"
        root.recording = true
        root.duration = 0

        var timestamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss")
        var ext = ".mp4"
        var file = root.saveDir + "/recording_" + timestamp + ext
        root.lastFile = file

        var args = ["-f", file, "-c", "h264_vaapi", "-d", "/dev/dri/renderD128"]
        if (mode === "window") {
            args.push("-g", "$(slurp -or)")
        } else if (mode === "region") {
            args.push("-g", "$(slurp)")
        }
        if (audio) {
            args.push("--audio", "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__sink.monitor")
        }

        // Use bash -c to expand slurp command substitution
        recorderProcess.command = ["bash", "-c", root.wfRecorder + " " + args.join(" ")]
        recorderProcess.running = true
        durationTimer.running = true
    }

    function stop() {
        if (!root.recording) return
        recorderProcess.running = false
        // wf-recorder handles SIGINT gracefully
        durationTimer.running = false
        root.recording = false
        root.status = "encoding"
        // Wait a bit for encoding to finish
        encodingTimer.running = true
    }

    function toggle() {
        if (root.recording) root.stop()
        else root.start("screen", true)
    }

    // Show notification when file is ready
    function notifyReady() {
        if (root.lastFile === "") return
        var name = root.lastFile.split("/").pop()
        Quickshell.execDetached(["notify-send", "-a", "ndotshell", "-i", "media-record",
            "Grabación guardada", name + " en ~/Descargas/ScreenRecordings"])
    }

    Process {
        id: recorderProcess
        onExited: (code) => {
            if (code !== 0 && root.status === "recording") {
                root.status = "error"
                Quickshell.execDetached(["notify-send", "-a", "ndotshell", "-i", "error",
                    "Error grabando", "Código " + code + ". ¿wf-recorder instalado?"])
            }
        }
    }

    Timer {
        id: durationTimer
        interval: 1000
        running: false
        repeat: true
        onTriggered: root.duration++
    }

    Timer {
        id: encodingTimer
        interval: 3000
        running: false
        repeat: false
        onTriggered: {
            root.status = "idle"
            root.notifyReady()
        }
    }

    // Quick panel integration: expose actions
    function startScreen() { root.start("screen", true) }
    function startWindow() { root.start("window", true) }
    function startRegion() { root.start("region", true) }
    function startScreenNoAudio() { root.start("screen", false) }
}