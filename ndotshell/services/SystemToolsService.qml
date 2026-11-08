pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// System tools: Fastfetch (preview + config Nothing) and Ryoku/Ryostore
// compatibility detection for the Settings panel. Everything local:
// detection via `command -v`, outputs via Process, zero network.
Singleton {
    id: root

    // ===== fastfetch =====
    property bool ffInstalled: false
    property string ffOutput: ""
    property bool ffBusy: false
    property bool ffConfigWritten: false

    // ===== ryoku / ryostore / ryotunes / hub =====
    property bool ryokuInstalled: false
    property bool ryostoreInstalled: false
    property bool ryotunesInstalled: false
    property bool hubInstalled: false
    property bool hubRashin: false       // rashin (theme daemon) status
    property string ryokuVersion: ""
    property string ryokuRelease: ""     // ej: "Amaterasu v1.0.6"
    property string pluginList: ""
    property bool probing: false

    Component.onCompleted: {
        probe()
        ffFetch()
    }

    function probe() {
        root.probing = true
        prober.exec(["sh", "-c",
            "command -v fastfetch >/dev/null 2>&1 && echo ff=yes || echo ff=no; " +
            "command -v ryoku >/dev/null 2>&1 && echo ryoku=yes || echo ryoku=no; " +
            "command -v ryostore >/dev/null 2>&1 && echo store=yes || echo store=no; " +
            "command -v ryotunes >/dev/null 2>&1 && echo tunes=yes || echo tunes=no; " +
            "command -v ryoku-hub >/dev/null 2>&1 && echo hub=yes || echo hub=no; " +
            "command -v ryoku-hub >/dev/null 2>&1 && ryoku-hub rashin status 2>/dev/null | grep -q true && echo rashin=yes || echo rashin=no; " +
            "command -v ryoku >/dev/null 2>&1 && ryoku status 2>/dev/null | grep '^release:' | cut -d: -f2- | xargs || true"])
    }

    function ffFetch() {
        if (!root.ffInstalled) return
        root.ffBusy = true
        ffRunner.exec(["fastfetch", "--pipe"])
    }

    // Escribe un config.jsonc estilo Nothing (acento rojo, logo dot-matrix)
    function writeNothingConfig() {
        const cfg = [
            '{',
            '  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",',
            '  "logo": { "type": "small", "padding": { "top": 1, "left": 2, "right": 3 } },',
            '  "display": {',
            '    "separator": "  │  ",',
            '    "color": { "keys": "#d71921", "title": "#f5f5f5" }',
            '  },',
            '  "modules": [',
            '    { "type": "title", "key": "╭─ DREW" },',
            '    { "type": "os", "key": "│ OS" },',
            '    { "type": "kernel", "key": "│ KERNEL" },',
            '    { "type": "wm", "key": "│ WM" },',
            '    { "type": "shell", "key": "│ SHELL" },',
            '    { "type": "terminal", "key": "│ TERM" },',
            '    { "type": "cpu", "key": "│ CPU" },',
            '    { "type": "gpu", "key": "│ GPU" },',
            '    { "type": "memory", "key": "│ MEM" },',
            '    { "type": "break", "key": "│" },',
            '    { "type": "colors", "paddingLeft": 2, "symbol": "circle" }',
            '  ]',
            '}'
        ].join("\n")
        writer.exec(["sh", "-c",
            "mkdir -p ~/.config/fastfetch && cat > ~/.config/fastfetch/config.jsonc << 'FFEOF'\n" +
            cfg + "\nFFEOF\necho written"])
    }

    function listRyokuPlugins() {
        if (!root.ryokuInstalled) return
        prober2.exec(["sh", "-c", "ryoku plugin list 2>&1 | head -30"])
    }

    function openHub() {
        Quickshell.execDetached(["sh", "-c", "ryoku-shell hub open >/dev/null 2>&1 &"])
    }

    function openStore() {
        // Ryostore vive en la terminal: lo abrimos en una kitty nueva
        Quickshell.execDetached(["sh", "-c",
            "command -v kitty >/dev/null 2>&1 && kitty --title ryostore sh -c 'ryostore catalog; exec sh' >/dev/null 2>&1 &"])
    }

    function openRyotunes() {
        // ryotunes pide a ryotunesd mostrar el cliente nativo
        Quickshell.execDetached(["sh", "-c", "command -v ryotunes >/dev/null 2>&1 && ryotunes >/dev/null 2>&1 &"])
    }

    function openHubGui() {
        // Hub GUI: si el daemon ryoku-shell está vivo lo usa; si no,
        // lanza el config del hub DIRECTO con qs (sin necesidad de daemon).
        Quickshell.execDetached(["sh", "-c",
            "if [ -S \"$XDG_RUNTIME_DIR/ryoku-shell.sock\" ]; then " +
            "ryoku-shell hub open >/dev/null 2>&1; else " +
            "qs -p /usr/share/ryoku/config/quickshell/hub/shell.qml >/dev/null 2>&1 & fi"])
    }

    function hubCli() {
        // ryoku-hub en kitty para comandos directos (desktop, keybinds, phone…)
        Quickshell.execDetached(["sh", "-c",
            "command -v kitty >/dev/null 2>&1 && kitty --title ryoku-hub sh -c 'ryoku-hub 2>&1 | head -40; exec sh' >/dev/null 2>&1 &"])
    }

    Process {
        id: prober
        stdout: StdioCollector {
            onStreamFinished: {
                root.probing = false
                const lines = text.trim().split("\n")
                for (const l of lines) {
                    if (l === "ff=yes") root.ffInstalled = true
                    if (l === "ryoku=yes") root.ryokuInstalled = true
                    if (l === "store=yes") root.ryostoreInstalled = true
                    if (l === "tunes=yes") root.ryotunesInstalled = true
                    if (l === "hub=yes") root.hubInstalled = true
                    if (l === "rashin=yes") root.hubRashin = true
                    if (l !== "" && !l.includes("="))
                        root.ryokuRelease = l
                }
                // release va a ryokuVersion para compat con la UI existente
                if (root.ryokuRelease !== "") root.ryokuVersion = root.ryokuRelease
            }
        }
    }

    Process { id: prober2
        stdout: StdioCollector {
            onStreamFinished: root.pluginList = text.trim()
        }
    }

    Process {
        id: ffRunner
        command: ["fastfetch", "--pipe"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.ffBusy = false
                root.ffOutput = text.trim()
            }
        }
    }

    Process { id: writer
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.includes("written")) {
                    root.ffConfigWritten = true
                    root.ffFetch()
                }
            }
        }
    }
}