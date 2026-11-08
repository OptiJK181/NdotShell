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
    property bool shellDaemon: false     // daemon ryoku-shell vivo
    property string ryokuVersion: ""
    property string ryokuRelease: ""     // ej: "Amaterasu v1.0.6"
    property string pluginList: ""
    property string barWidgets: ""       // salida de ryoku-shell bar list
    property string themeSchemes: ""     // salida de ryoku-shell theme catalog
    property bool probing: false

    Component.onCompleted: {
        probe()
        probeDaemon()
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
            "command -v ryoku-shell >/dev/null 2>&1 && ryoku-shell status 2>/dev/null | grep -q running && echo shd=yes || echo shd=no; " +
            "command -v ryoku >/dev/null 2>&1 && ryoku status 2>/dev/null | grep '^release:' | cut -d: -f2- | xargs || true"])
    }

    // probe ligero solo del daemon (para que el toggle responda al instante)
    function probeDaemon() {
        daemonProber.exec(["sh", "-c",
            "command -v ryoku-shell >/dev/null 2>&1 && ryoku-shell status 2>/dev/null | grep -q running && echo yes || echo no"])
    }

    function startDaemon() {
        // SOLO transeúnte: el daemon respawnea la shell de ryoku (bar+dock
        // duplicado con NdotShell). Se usa dentro de openHubGui() y se mata.
        Quickshell.execDetached(["sh", "-c",
            "S=\"$XDG_RUNTIME_DIR/ryoku-shell.sock\"; " +
            "if ! [ -S \"$S\" ]; then setsid ryoku-shell daemon >/dev/null 2>&1 < /dev/null & " +
            "i=0; while ! [ -S \"$S\" ] && [ $i -lt 20 ]; do sleep 0.15; i=$((i+1)); done; fi"])
        delayProbe.restart()
    }

    function cleanupRyoku() {
        // mata daemon + watcher + la shell de ryoku si alguien la dejó
        // corriendo — NdotShell ya trae su propia bar y dock.
        // pgrep -x (nombre exacto) en vez de pkill -f para NO auto-machearnos.
        Quickshell.execDetached(["sh", "-c",
            "D=\"ryoku-shell\"; " +
            "for p in $(pgrep -x \"$D\"); do kill $p 2>/dev/null; done; " +
            "pkill -f \"wm-hyprland watc[h]\" 2>/dev/null; " +
            "sleep 0.5; qs kill -c shell 2>/dev/null; " +
            "for p in $(pgrep -x \"$D\"); do kill $p 2>/dev/null; done; exit 0"])
        delayProbe.restart()
    }

    function openHubGui() {
        // Helper único (~/.local/bin/ryoku-hub-open): daemon TRANSEÚNTE.
        // El mismo script que ejecuta el app launcher vía la entrada
        // .desktop override. Antes de ejecutarlo, se auto-sincroniza
        // desde el config dir instalado (así las updates lo refrescan).
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p \"$HOME/.local/bin\"; " +
            "SRC=\"$HOME/.config/quickshell/ndotshell/scripts/system/ryoku-hub-open.sh\"; " +
            "if [ -f \"$SRC\" ]; then cp \"$SRC\" \"$HOME/.local/bin/ryoku-hub-open\"; " +
            "chmod +x \"$HOME/.local/bin/ryoku-hub-open\"; fi; " +
            "exec \"$HOME/.local/bin/ryoku-hub-open\""])
    }

    function fetchBarWidgets() {
        if (!root.ryokuInstalled) return
        barProber.exec(["sh", "-c", "ryoku-shell bar list 2>&1 | head -20"])
    }

    function fetchThemeSchemes() {
        if (!root.ryokuInstalled) return
        themeProber.exec(["sh", "-c",
            "ryoku-shell theme catalog 2>/dev/null | jq -r '.[].label' 2>/dev/null || " +
            "ryoku-shell theme catalog 2>&1 | head -24"])
    }

    Timer {
        id: delayProbe
        interval: 900
        onTriggered: root.probeDaemon()
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
        if (!root.hubInstalled) return
        prober2.exec(["sh", "-c",
            "ryoku-hub desktop plugins list 2>/dev/null | " +
            "jq -r '.plugins[] | \"\\(.name) [\\(.status)]\"' 2>/dev/null | head -12"])
    }

    function openHub() {
        // la tarjeta de Ryostore usa este alias — mismo camino seguro
        openHubGui()
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
                    if (l === "shd=yes") root.shellDaemon = true
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

    Process { id: daemonProber
        stdout: StdioCollector {
            onStreamFinished: root.shellDaemon = text.trim() === "yes"
        }
    }

    Process { id: barProber
        stdout: StdioCollector {
            onStreamFinished: root.barWidgets = text.trim()
        }
    }

    Process { id: themeProber
        stdout: StdioCollector {
            onStreamFinished: root.themeSchemes = text.trim()
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