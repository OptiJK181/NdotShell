pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import "../modules/common/functions/PaletteMath.js" as PM
import "../modules/common/functions/ScreenThemes.js" as ST
import "../modules/common/functions/MatugenMath.js" as MG

// NdotShell's channels. One permanent design — Nothing OS: black surfaces,
// hairline grey, white ink, Ndot 55 and one accent colour — in six accent
// channels. The channel is remembered across restarts.
// Theme.qml (and ScrapbookTheme.qml's wallpaper board) read the active
// palette from here, so everything that already says Theme.colBorder /
// Theme.accentCyan / Theme.accentMint re-colours live when it changes.
//
//   nothing     Ndot Red       the signature #d71921 (default)
//   ndotmono    Ndot Mono      white / silver, no hue at all
//   ndotamber   Ndot Amber     warm amber
//   ndotlime    Ndot Lime      acid lime
//   ndotblue    Ndot Blue      cobalt
//   ndotviolet  Ndot Violet    violet
//   matugen     Wallpaper      colours pulled from the current wallpaper
//              by matugen (needs `matugen` installed; see README)
//   custom      Custom palette  applied from the Palette tool
//
// The chosen theme (a group's accent, or the wallpaper for matugen) is also put on
// GTK, Qt and KDE apps through matugen, see "System-wide GTK / Qt / KDE colours" below.
//
// The picker is the THEME tab of Edit Desktop (EditThemeBoard.qml, on the
// shelf of EditTray.qml): each group is a little preview of the shell in its
// colours. It opens from a keybind:
//   qs -c ndotshell ipc call theme toggle
// and the rest of the IPC:
//   qs -c ndotshell ipc call theme set nightcord
//   qs -c ndotshell ipc call theme cycle
//   qs -c ndotshell ipc call theme get
//
// Each palette is the same set of roles:
//   border      outlines, shadows, dark text (Theme.colBorder)
//   A, B        the two accent stops of the cyan -> mint gradients
//               (Theme.accentCyan, Theme.accentMint)
//   deep        the dark dialog / scrim colour
//   hoverTint   the pale hover wash on white buttons
//   divider     menu separator lines
//   boardBg, boardDot   the wallpaper board's tray and its dot grid
//   rimHi, bezel, wallLight, wallMid, wallDark, hardware, lens, glint
//   lockMint, lockPink   optional: pin the lockscreen's two accents (otherwise B and A)
//               the phone mock-up's plastics (PhoneBody.qml)
// The unit colours are picked by eye from each group's colour in the game
// (blue, green, pink, orange, purple); tweak any of them right here.
Singleton {
    id: root

    readonly property var baseGroups: [
        { id: "nothing", name: "Ndot Red", c: { dot: true, mono: true, border: "#2b2b2b", A: "#d71921", B: "#f5f5f5", deep: "#0a0a0a", rimHi: "#9a9a9a", bezel: "#1c1c1c", wallLight: "#c9c9c9", wallMid: "#6e6e6e", wallDark: "#2e2e2e", hardware: "#0d0d0d", divider: "#f2f2f2", lens: "#d71921", glint: "#ff4b52", hoverTint: "#f2f2f2", boardBg: "#f4f4f4", boardDot: "#d4d4d4", lockMint: "#e6e6e6", lockPink: "#d71921" } },
        { id: "ndotmono", name: "Ndot Mono", c: { dot: true, mono: true, border: "#2b2b2b", A: "#f5f5f5", B: "#bdbdbd", deep: "#0a0a0a", rimHi: "#9a9a9a", bezel: "#1c1c1c", wallLight: "#c9c9c9", wallMid: "#6e6e6e", wallDark: "#2e2e2e", hardware: "#0d0d0d", divider: "#f2f2f2", lens: "#6a6a6a", glint: "#d0d0d0", hoverTint: "#f2f2f2", boardBg: "#f4f4f4", boardDot: "#d4d4d4", lockMint: "#e6e6e6", lockPink: "#9e9e9e" } },
        { id: "ndotamber", name: "Ndot Amber", c: { dot: true, mono: true, border: "#2b2b2b", A: "#ff9f0a", B: "#ffd166", deep: "#0a0a0a", rimHi: "#9a9a9a", bezel: "#1c1c1c", wallLight: "#c9c9c9", wallMid: "#6e6e6e", wallDark: "#2e2e2e", hardware: "#0d0d0d", divider: "#f2f2f2", lens: "#c2740a", glint: "#ffc46b", hoverTint: "#f2f2f2", boardBg: "#f4f4f4", boardDot: "#d4d4d4", lockMint: "#e6e6e6", lockPink: "#ff9f0a" } },
        { id: "ndotlime", name: "Ndot Lime", c: { dot: true, mono: true, border: "#2b2b2b", A: "#c7f464", B: "#eaffb0", deep: "#0a0a0a", rimHi: "#9a9a9a", bezel: "#1c1c1c", wallLight: "#c9c9c9", wallMid: "#6e6e6e", wallDark: "#2e2e2e", hardware: "#0d0d0d", divider: "#f2f2f2", lens: "#8fae3f", glint: "#e2ff9c", hoverTint: "#f2f2f2", boardBg: "#f4f4f4", boardDot: "#d4d4d4", lockMint: "#e6e6e6", lockPink: "#c7f464" } },
        { id: "ndotblue", name: "Ndot Blue", c: { dot: true, mono: true, border: "#2b2b2b", A: "#4a7dff", B: "#9db9ff", deep: "#0a0a0a", rimHi: "#9a9a9a", bezel: "#1c1c1c", wallLight: "#c9c9c9", wallMid: "#6e6e6e", wallDark: "#2e2e2e", hardware: "#0d0d0d", divider: "#f2f2f2", lens: "#3358b8", glint: "#9db9ff", hoverTint: "#f2f2f2", boardBg: "#f4f4f4", boardDot: "#d4d4d4", lockMint: "#e6e6e6", lockPink: "#4a7dff" } },
        { id: "ndotviolet", name: "Ndot Violet", c: { dot: true, mono: true, border: "#2b2b2b", A: "#a86bff", B: "#d3b0ff", deep: "#0a0a0a", rimHi: "#9a9a9a", bezel: "#1c1c1c", wallLight: "#c9c9c9", wallMid: "#6e6e6e", wallDark: "#2e2e2e", hardware: "#0d0d0d", divider: "#f2f2f2", lens: "#7747b8", glint: "#d3b0ff", hoverTint: "#f2f2f2", boardBg: "#f4f4f4", boardDot: "#d4d4d4", lockMint: "#e6e6e6", lockPink: "#a86bff" } }
    ]

    // NdotShell's channels: one permanent Nothing design (mono dots, black
    // slab, hairline grey, Ndot 55) in six accent channels. Every channel
    // shares the same design roles and only swaps the accent, so the shell
    // never leaves its own identity the way the Project Sekai unit themes did.
    //
    // `dot: true` puts the Ndot 55 dot-matrix face on the big numerals;
    // `mono: true` keeps every derived colour (attribute pastels, workspace
    // dots, system scheme) neutral so the one accent stays the only hue.
    readonly property var extraGroups: []

    // The base groups plus the wallpaper theme. The matugen row carries the
    // live palette once matugen has produced one (so the picker's swatch
    // shows the real colours), and Virtual Singer's until then.
    readonly property var groups: root.baseGroups.concat(root.extraGroups, [
        { id: "matugen", name: "Wallpaper (matugen)", c: root.matugenPalette || root.baseGroups[0].c }
    ], root.customPalette ? [
        { id: "custom", name: "Custom palette", c: root.customPalette }
    ] : [])

    // ===== custom palette (the Palette tool's Apply) =====
    // Five colours the user applied from the Palette tool (modules/sekai/palette), or
    // null if they never did. The "custom" row of `groups` exists only once there are
    // some, and its colours are PaletteMath.toShell of them: the same function the
    // tool's live preview draws with, so Apply looks like the preview. Nothing in the
    // tool's preview, shuffling or favourites touches this; only applyPalette() does.
    property var customColors: null
    readonly property var customPalette: root.customColors ? PM.toShell(root.customColors) : null

    FileView {
        id: customBoot
        path: root.stateDir + "/custom-palette"
        blockLoading: true
        printErrors: false
    }

    // Read at startup with the other state files, BEFORE the saved theme id comes back
    // (that is asynchronous), so a saved "custom" id finds its row and is accepted.
    function bootCustom() {
        try {
            const c = PM.parse(String(customBoot.text()).trim())
            if (c && root.customColors === null)
                root.customColors = c
        } catch (e) {
        }
    }

    // Wear `colors` (five #rrggbb) as the "custom" theme and remember them. Returns
    // false if they are not five colours. This is the ONLY way the tool changes the
    // theme, and it is only called by PaletteService.apply().
    function applyPalette(colors) {
        const c = PM.parse(colors)
        if (!c)
            return false
        root.customColors = c
        customSaver.save(c.join(","))
        root.setTheme("custom")
        return true
    }

    Process {
        id: customSaver

        property string pending: ""

        function save(csv) {
            if (customSaver.running) {
                customSaver.pending = csv
                return
            }
            customSaver.pending = ""
            customSaver.exec(["sh", root.script, "save-custom", csv])
        }

        onExited: {
            if (customSaver.pending !== "") {
                const csv = customSaver.pending
                customSaver.pending = ""
                customSaver.exec(["sh", root.script, "save-custom", csv])
            }
        }
    }

    property string current: "nothing"

    // Three modes (see Theme.qml): light, dark (white outline) and darker
    // (near-black, dark outline). `dark` follows the system colour scheme
    // and is true for both dark looks; `darkerPref` picks which dark look.
    // Both are kept across restarts.
    //   cycle:  qs -c ndotshell ipc call theme modeCycle
    //   set:    qs -c ndotshell ipc call theme modeSet light|dark|darker
    //
    // Both are set from the saved value when this singleton finishes loading
    // (bootSaved(), from Component.onCompleted), by reading the state files
    // synchronously. Before, they sat on the default (light) until the async
    // `load-dark` below answered a moment later, and that gap was the light
    // flash on every launch / reload. If nothing is saved yet (a first run)
    // the shell starts DARK (see bootSaved()).
    property bool dark: true
    property bool darkTouched: false
    property bool darkerPref: false
    property bool darkerTouched: false

    readonly property string stateDir: {
        const xdg = Quickshell.env("XDG_STATE_HOME")
        return ((xdg && xdg.length > 0) ? xdg : (Quickshell.env("HOME") + "/.local/state")) + "/ndotshell"
    }

    // Same files theme-state.sh writes (`dark`, `darker`: "on" / "off").
    FileView {
        id: darkBoot
        path: root.stateDir + "/dark"
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: darkerBoot
        path: root.stateDir + "/darker"
        blockLoading: true
        printErrors: false
    }

    // "on" / "off" from one of the state files, or null if it can't be read.
    function bootFlag(view) {
        try {
            const v = String(view.text()).trim()
            if (v === "on")
                return true
            if (v === "off")
                return false
        } catch (e) {
        }
        return null
    }

    // Takes the saved dark / darker values, unless one was already changed.
    // Nothing has been drawn yet when this runs, so the first frame is already
    // in the right mode. It does not save anything or count as a click.
    function bootSaved() {
        const d = root.bootFlag(darkBoot)
        if (d !== null && !root.darkTouched)
            root.dark = d
        // A first run: nothing saved yet, so the shell stays on its dark default.
        // Remember it, and put the system colour scheme in step once, so the bar
        // (which follows the system scheme) does not pull the shell back to light.
        if (d === null && !root.darkTouched)
            root.firstRunDark()
        const k = root.bootFlag(darkerBoot)
        if (k !== null && !root.darkerTouched)
            root.darkerPref = k
    }

    // True from a first run until the system colour scheme has become dark (or
    // 8 s have passed). While it is true the bar ignores a light scheme instead
    // of following it, because the scheme has not been changed yet.
    property bool firstDarkPending: false

    function firstRunDark() {
        root.darkTouched = true
        root.dark = true
        root.firstDarkPending = true
        darkSaver.save(true)
        root.syncSystemScheme(false)
        firstDarkTimer.restart()
    }

    function firstDarkDone() {
        root.firstDarkPending = false
        firstDarkTimer.stop()
    }

    Timer {
        id: firstDarkTimer
        interval: 8000
        onTriggered: root.firstDarkPending = false
    }

    readonly property bool darker: root.dark && root.darkerPref
    readonly property string mode: !root.dark ? "light" : (root.darkerPref ? "darker" : "dark")

    // Dark or light, from the system colour scheme; keeps whichever dark
    // look was chosen last.
    function setDark(on) {
        root.darkTouched = true
        if (root.dark === on)
            return
        root.dark = on
        darkSaver.save(on)
    }

    function setDarker(on) {
        root.darkerTouched = true
        if (root.darkerPref === on)
            return
        root.darkerPref = on
        darkerSaver.save(on)
    }

    function setMode(m) {
        if (m === "light") {
            root.setDark(false)
        } else if (m === "dark" || m === "darker") {
            root.setDarker(m === "darker")
            root.setDark(true)
        }
    }

    function nextMode() {
        return root.mode === "light" ? "dark" : (root.mode === "dark" ? "darker" : "light")
    }

    function cycleMode() {
        root.setMode(root.nextMode())
    }

    function toggleDark() {
        root.setDark(!root.dark)
    }

    // The bar's Dark / light button and the Quick Panel's Dark Mode tile both
    // call this: cycles light -> dark -> darker and, when that crosses light <->
    // dark, changes the system colour scheme too. (Moved here from
    // UtilButtons.qml unchanged, so the two can't drift apart.)
    function cycleModeAndSystem() {
        const wasDark = root.dark
        root.cycleMode()
        root.syncSystemScheme(wasDark)
    }

    // Same, for picking a mode by name (the Settings Panel's Light / Dark /
    // Darker chips): the system colour scheme only changes when the pick
    // crosses light <-> dark.
    function setModeAndSystem(m) {
        const wasDark = root.dark
        root.setMode(m)
        root.syncSystemScheme(wasDark)
    }

    // Puts the system colour scheme (GTK / libadwaita / KDE) in step with the
    // shell after a mode change that started from `wasDark`.
    function syncSystemScheme(wasDark) {
        // Light -> Dark (white outline) -> Darker (dark outline) -> Light.
        // The system scheme only changes when the shell crosses light <-> dark,
        // so Dark -> Darker doesn't touch it.
        const goDark = root.dark
        if (goDark === wasDark)
            return
        // switchwall.sh runs illogical-impulse's "wallpaper is lower resolution
        // than your monitor, upscale it?" check (Upscayl) from switch(), as a
        // BACKGROUND job (`check_and_prompt_upscale ... &`), and it does so
        // even with --noswitch. Flipping light/dark doesn't change the
        // wallpaper, so that notice is noise here. The script runs with a
        // small notify-send stub first on PATH that drops only messages
        // mentioning Upscayl / resolution and hands every other notification
        // to the real notify-send. The stub lives in a fixed cache folder and
        // is never deleted: the background job can outlive switchwall.sh
        // itself, and a temp folder removed on exit would let the notice
        // through. Picking a wallpaper doesn't come through here, so its
        // notice is unchanged.
        const script = "s=\"$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh\"\n"
            + "if [ -f \"$s\" ]; then\n"
            + "d=\"${XDG_CACHE_HOME:-$HOME/.cache}/ndotshell/nonotify\"\n"
            + "mkdir -p \"$d\" || exit 1\n"
            + "real=$(PATH=\"${PATH//$d:/}\" command -v notify-send) || real=true\n"
            + "printf '%s\\n' '#!/bin/sh' 'case \"$*\" in *[Uu]psc*|*[Rr]esolution*) exit 0;; esac' \"exec \\\"$real\\\" \\\"\\$@\\\"\" > \"$d/notify-send.tmp\" && chmod +x \"$d/notify-send.tmp\" && mv \"$d/notify-send.tmp\" \"$d/notify-send\"\n"
            + "PATH=\"$d:$PATH\" bash \"$s\" --mode \"$1\" --noswitch\n"
            + "else gsettings set org.gnome.desktop.interface color-scheme \"prefer-$1\"; fi\n"
        Quickshell.execDetached(["bash", "-c", script, "bash", goDark ? "dark" : "light"])
    }

    readonly property int index: {
        for (let i = 0; i < root.groups.length; i++)
            if (root.groups[i].id === root.current)
                return i
        return 0
    }
    readonly property var palette: root.groups[root.index].c
    readonly property string currentName: root.groups[root.index].name

    // Set once the user (or IPC) has picked something this session, so the
    // startup load below can't land late and undo it.
    property bool touched: false

    // True once the saved theme has been read from disk (or the user picked one first).
    // Until then `current` is just the built-in default, and anything that copies the
    // palette out to other apps (AppThemeService) must wait, or it would paint them in
    // the default colours for a moment on every start.
    property bool themeLoaded: false

    function has(id) {
        return root.groups.some(g => g.id === id)
    }

    function setTheme(id) {
        if (!root.has(id))
            return
        root.touched = true
        if (root.current === id)
            return
        const oldTheme = root.current;
        root.current = id
        saver.save(id)
        HookService.emit("theme", [oldTheme, id]);
    }

    // ===== one theme per monitor (Theme.of(), setting theme.perMonitor) =====
    // With it on, a monitor can wear a theme of its own on what sits on it (the bar, the dock,
    // the desktop widgets, the Quick Panel when it opens there). The main monitor (the first,
    // WallpaperService.themeScreen) wears the shell's theme, `current`, which is also what apps,
    // Settings and the popups wear; the others follow it until they pick their own. The rules
    // are ScreenThemes.js; the choices are the setting theme.screens.
    readonly property bool perMonitor: SettingsService.flag("theme.perMonitor")
    readonly property string mainScreen: WallpaperService.themeScreen
    readonly property var screenGroups: ST.parse(SettingsService.get("theme.screens"))
    readonly property var groupIds: root.groups.map(g => g.id)

    // The theme monitor `name` wears.
    function themeFor(name) {
        return ST.themeFor(root.screenGroups, root.perMonitor, name, root.mainScreen, root.current, root.groupIds)
    }

    // Does monitor `name` wear anything but the shell's own palette? (Theme.of() makes it a
    // ThemeSet of its own only then.) A monitor on Matugen counts once its own wallpaper's
    // colours are in, as long as that wallpaper isn't the main monitor's.
    function hasScreenTheme(name) {
        const id = root.themeFor(name)
        if (id === "matugen")
            return root.screenMatugen[name] !== undefined
        return id !== root.current
    }

    function paletteFor(name) {
        const id = root.themeFor(name)
        // A monitor's own matugen colours wear the pinned accents too (matugen.pinA / pinB),
        // put on here so a pin change reaches every monitor at once.
        if (id === "matugen")
            return root.screenMatugen[name] ? MG.applyPins(root.screenMatugen[name], root.matugenPinA, root.matugenPinB) : root.palette
        if (id === root.current)
            return root.palette
        const g = root.groups.find(x => x.id === id)
        return g ? g.c : root.palette
    }

    // A theme picker on monitor `name` (Edit Desktop's THEME tab, Settings > Quick > Colours):
    // the shell's theme from the main monitor (or with the setting off), that monitor's own
    // from any other.
    function pickTheme(name, id) {
        if (ST.target(root.perMonitor, name, root.mainScreen) === "screen")
            root.setScreenTheme(name, id)
        else
            root.setTheme(id)
    }

    // Monitor `name` wears `id` from now on; the main monitor's theme (or "") makes it follow
    // the main monitor again.
    function setScreenTheme(name, id) {
        const next = ST.pick(root.screenGroups, name, id, root.mainScreen, root.current, root.groupIds)
        SettingsService.set("theme.screens", Object.keys(next).length > 0 ? JSON.stringify(next) : "")
    }

    // ===== matugen, per monitor =====
    // Each monitor other than the main one that wears Matugen gets matugen run on ITS
    // wallpaper (written to screen-<name>.json); one showing the main monitor's picture just
    // wears the main colours. { monitor name: shell palette }, filled as the runs finish.
    property var screenMatugen: ({})
    // { monitor name: the image it was last run for }
    property var screenMatugenFor: ({})
    property var screenMatugenQueue: []

    function refreshScreenMatugen() {
        const names = Quickshell.screens.map(sc => sc.name)
        const want = ST.matugenScreens(root.screenGroups, root.perMonitor, names, root.mainScreen, root.current, root.groupIds)
        const mainImg = WallpaperService.imageFor(WallpaperService.pathFor(root.mainScreen))
        const keep = {}
        const queue = []
        for (const n of want) {
            const img = WallpaperService.imageFor(WallpaperService.pathFor(n))
            if (img === "" || img === mainImg)
                continue
            if (root.screenMatugen[n] !== undefined && root.screenMatugenFor[n] === img + "|" + root.matugenType + "|" + root.matugenContrast)
                keep[n] = root.screenMatugen[n]
            else
                queue.push({ name: n, img: img })
        }
        root.screenMatugen = keep
        root.screenMatugenQueue = queue
        root.pumpScreenMatugen()
    }

    function pumpScreenMatugen() {
        if (screenMatugenProc.running || root.screenMatugenQueue.length === 0)
            return
        const job = root.screenMatugenQueue[0]
        root.screenMatugenQueue = root.screenMatugenQueue.slice(1)
        screenMatugenProc.job = job
        const out = root.matugenPath.replace(/colors\.json$/, "screen-" + job.name + ".json")
        // The same scheme and contrast as the main monitor (Edit Desktop > THEME > Matugen), but
        // its own first colour: the seed is an index into the MAIN wallpaper's colours.
        const extra = MG.applyArgs(-1, root.matugenContrast)
        screenMatugenProc.exec(["sh", "-c", 'sh "$0" apply "$1" "$2" "$3" "$5" "$6" && cat "$4"',
            root.matugenScript, job.img, root.matugenType, "screen-" + job.name, out, extra[0], extra[1]])
    }

    Process {
        id: screenMatugenProc
        property var job: null

        stdout: StdioCollector {
            onStreamFinished: {
                const job = screenMatugenProc.job
                if (!job)
                    return
                try {
                    const pal = root.buildMatugenPalette(JSON.parse(text))
                    if (pal) {
                        const next = Object.assign({}, root.screenMatugen)
                        next[job.name] = pal
                        root.screenMatugen = next
                        const done = Object.assign({}, root.screenMatugenFor)
                        done[job.name] = job.img + "|" + root.matugenType + "|" + root.matugenContrast
                        root.screenMatugenFor = done
                    }
                } catch (e) {
                    console.log("[ThemeService] matugen (" + job.name + "): couldn't read its colours", e)
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.log("[ThemeService] matugen (" + (screenMatugenProc.job ? screenMatugenProc.job.name : "?") + "):", text.trim())
            }
        }
        onExited: Qt.callLater(root.pumpScreenMatugen)
    }

    // Anything that changes who needs a run, or on what picture.
    Timer {
        id: screenMatugenDebounce
        interval: 250
        onTriggered: root.refreshScreenMatugen()
    }
    readonly property string screenMatugenKey: [root.perMonitor, root.current, JSON.stringify(root.screenGroups),
        JSON.stringify(WallpaperService.screenPaths), WallpaperService.defaultPath, root.matugenType, root.matugenContrast,
        Quickshell.screens.map(sc => sc.name).join(",")].join("|")
    onScreenMatugenKeyChanged: screenMatugenDebounce.restart()

    // ===== matugen =====
    // The knobs (Edit Desktop > THEME > Matugen's controls, EditMatugenControls.qml), each a
    // setting, cleaned by MatugenMath.js. Changing one re-runs matugen (onMatugenTuningChanged).
    readonly property string matugenType: MG.cleanScheme(SettingsService.get("matugen.scheme"))
    // -1 = Auto. An index the current wallpaper has no colour for counts as Auto
    // (matugenSources is that list; until it has been read, the index is trusted and
    // matugen-state.sh falls back to the first colour if it is out of range).
    readonly property int matugenSeed: root.matugenSources.length > 0
        ? MG.cleanSeed(SettingsService.get("matugen.seed"), root.matugenSources.length)
        : Math.max(-1, Math.floor(Number(SettingsService.get("matugen.seed")) || 0))
    readonly property real matugenContrast: MG.cleanContrast(SettingsService.get("matugen.contrast"))
    readonly property string matugenPinA: MG.cleanHex(SettingsService.get("matugen.pinA"))
    readonly property string matugenPinB: MG.cleanHex(SettingsService.get("matugen.pinB"))
    // One string for "any knob that changes what matugen makes" (the pins don't: they are
    // put on afterwards, in matugenPalette).
    readonly property string matugenTuning: root.matugenType + "|" + root.matugenSeed + "|" + root.matugenContrast
    onMatugenTuningChanged: {
        if (!SettingsService.loaded)
            return
        root.regenerate("", true)
        root.regenerateLock(true)
        if (root.current === "matugen")
            systemDebounce.restart()
    }

    // A run is going on (the controls show "Working").
    readonly property bool matugenBusy: matugenProc.running

    // The current wallpaper's candidate seed colours (matugen-state.sh sources), read
    // while the matugen theme is on; [] until then. The Seed swatches.
    property var matugenSources: []
    property string matugenSourcesFor: ""

    function readSources() {
        if (root.current !== "matugen" || !root.matugenInstalled)
            return
        const img = WallpaperService.imagePath
        if (img === "" || img === root.matugenSourcesFor)
            return
        root.matugenSourcesFor = img
        sourcesProc.exec(["sh", root.matugenScript, "sources", img])
    }

    Process {
        id: sourcesProc

        stdout: StdioCollector {
            onStreamFinished: root.matugenSources = MG.parseSources(text)
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.matugenSourcesFor = ""
        }
    }

    // Whether matugen is on the PATH at all: the Matugen tile says what is missing, and has
    // no controls, when it isn't. Asked once at startup (installing it means a restart).
    property bool matugenInstalled: true

    Process {
        running: true
        command: ["sh", root.matugenScript, "installed"]
        onExited: (exitCode, exitStatus) => {
            root.matugenInstalled = exitCode === 0
            root.readSources()
        }
    }

    // What matugen last wrote (scripts/theming/matugen-template.json), parsed, and
    // the shell palette derived from it. null until there is a valid one.
    property var matugenColors: null
    property string matugenRaw: ""
    // ...with the pinned accents (matugen.pinA / pinB) in place of matugen's own.
    readonly property var matugenPalette: root.matugenColors ? MG.applyPins(root.buildMatugenPalette(root.matugenColors), root.matugenPinA, root.matugenPinB) : null

    // The shell is a white-pill UI with dark ink on light accents whatever
    // the wallpaper, so the palette always takes the dark scheme's light
    // accents (primary, tertiary) and its dark tones (containers) plus the
    // light scheme's pale tones, rather than following matugen's dark/light
    // mode. The roles are mapped by tone, the way the hand-picked group
    // palettes are laid out; retune any line to taste.
    function buildMatugenPalette(d) {
        const dk = d && d.dark
        const lt = d && d.light
        if (!dk || !lt)
            return null
        const need = [
            [dk, ["primary", "on_primary", "primary_container", "secondary", "secondary_container", "tertiary", "inverse_primary", "outline"]],
            [lt, ["primary", "primary_container", "secondary_container", "surface", "surface_variant"]]
        ]
        for (let i = 0; i < need.length; i++)
            for (let j = 0; j < need[i][1].length; j++)
                if (!/^#[0-9a-fA-F]{6}$/.test(String(need[i][0][need[i][1][j]])))
                    return null
        return {
            border: dk.primary_container,                          // outlines, shadows, dark text
            A: dk.primary,
            B: dk.tertiary,
            deep: Qt.darker(Qt.color(dk.on_primary), 1.2),
            hoverTint: Qt.tint(Qt.color(lt.primary_container), Qt.rgba(1, 1, 1, 0.55)),
            divider: lt.surface_variant,
            boardBg: lt.surface,
            boardDot: lt.secondary_container,
            rimHi: dk.outline,
            bezel: Qt.darker(Qt.color(dk.primary_container), 1.35),
            wallLight: dk.secondary,
            wallMid: lt.primary,
            wallDark: dk.secondary_container,
            hardware: Qt.darker(Qt.color(dk.on_primary), 1.7),
            lens: dk.inverse_primary,
            glint: dk.primary
        }
    }

    // Runs matugen for the wallpaper on screen, if the matugen theme is the
    // active one (or the Discord theme needs its colours, see discordMatugen).
    // `force` re-runs even for a wallpaper it already did.
    property string matugenFor: ""

    function regenerate(path, force) {
        if (root.current !== "matugen" && !(root.discordSync && root.discordMatugen))
            return
        const img = path ? WallpaperService.imageFor(path) : WallpaperService.imagePath
        if (img === "" || (!force && img === root.matugenFor))
            return
        root.matugenFor = img
        matugenProc.run(img)
    }

    onCurrentChanged: {
        root.regenerate("", false)
        root.readSources()
    }

    // The wallpaper changed: start matugen straight away, so the colours are
    // ready around when the transition ends.
    Connections {
        target: WallpaperService
        function onTransitionStarted(from, to) {
            root.regenerate(to, false)
            Qt.callLater(root.readSources)
            if (root.current === "matugen")
                systemDebounce.restart()
        }
    }

    readonly property string matugenScript: Directories.script("theming/matugen-state.sh")

    readonly property string matugenPath: {
        const xdgCache = Quickshell.env("XDG_CACHE_HOME")
        const base = (xdgCache && xdgCache.length > 0) ? xdgCache : (Quickshell.env("HOME") + "/.cache")
        return base + "/ndotshell/matugen/colors.json"
    }

    // Same queue-one-behind convention as the savers: a switch mid-run isn't
    // dropped, the latest wallpaper is run once the current run ends.
    Process {
        id: matugenProc

        property string pending: ""

        function run(path) {
            if (matugenProc.running) {
                matugenProc.pending = path
                return
            }
            matugenProc.pending = ""
            matugenProc.exec(["sh", root.matugenScript, "apply", path, root.matugenType, "colors"].concat(MG.applyArgs(root.matugenSeed, root.matugenContrast)))
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.log("[ThemeService] matugen:", text.trim())
            }
        }

        onExited: (exitCode, exitStatus) => {
            console.log("[ThemeService] matugen finished, exit code", exitCode)
            if (exitCode === 0)
                colorsFile.reload()
            else
                root.matugenFor = ""   // let the next switch (or `theme refresh`) try again
            if (matugenProc.pending !== "") {
                const path = matugenProc.pending
                matugenProc.pending = ""
                matugenProc.exec(["sh", root.matugenScript, "apply", path, root.matugenType, "colors"].concat(MG.applyArgs(root.matugenSeed, root.matugenContrast)))
            }
        }
    }

    // Read whatever is there at startup (instant colours, before matugen has
    // re-run), and again whenever matugen rewrites it.
    FileView {
        id: colorsFile
        path: root.matugenPath
        watchChanges: true
        onFileChanged: colorsFile.reload()
        onLoaded: {
            const raw = colorsFile.text()
            if (raw === root.matugenRaw)
                return
            try {
                const d = JSON.parse(raw)
                if (root.buildMatugenPalette(d) === null) {
                    console.log("[ThemeService] matugen colours incomplete in", root.matugenPath)
                    return
                }
                root.matugenRaw = raw
                root.matugenColors = d
                console.log("[ThemeService] matugen palette applied, primary", d.dark.primary)
            } catch (e) {
                console.log("[ThemeService] couldn't parse", root.matugenPath, e)
            }
        }
    }

    // ===== matugen, for the lockscreen's own wallpaper =====
    // With the matugen theme and Settings -> Desktop -> Wallpaper -> Separate
    // Lockscreen Wallpaper both on, the lockscreen shows a different picture
    // from the desktop, so it wears THAT picture's colours (matugen run on it,
    // written to its own lock-colors.json) instead of the desktop wallpaper's.
    // In every other case the lockscreen uses the shell palette, as before.
    readonly property bool lockOwnColours: root.current === "matugen" && WallpaperService.separateLock
    property var lockMatugenColors: null
    property string lockMatugenRaw: ""
    property string lockMatugenFor: ""
    readonly property var lockMatugenPalette: root.lockMatugenColors ? MG.applyPins(root.buildMatugenPalette(root.lockMatugenColors), root.matugenPinA, root.matugenPinB) : null

    // What LockPalette.qml reads. Until matugen has produced the lockscreen's
    // colours (or if it fails) it keeps the shell palette, so it is never blank.
    readonly property var lockPalette: (root.lockOwnColours && root.lockMatugenPalette) ? root.lockMatugenPalette : root.palette

    function regenerateLock(force) {
        if (!root.lockOwnColours)
            return
        const img = WallpaperService.imageFor(WallpaperService.lockCurrentPath)
        if (img === "" || (!force && img === root.lockMatugenFor))
            return
        root.lockMatugenFor = img
        lockMatugenProc.run(img)
    }

    onLockOwnColoursChanged: root.regenerateLock(false)

    Connections {
        target: WallpaperService
        function onLockCurrentPathChanged() {
            root.regenerateLock(false)
        }
        function onReadyChanged() {
            root.regenerateLock(false)
        }
    }

    readonly property string lockMatugenPath: {
        const xdgCache = Quickshell.env("XDG_CACHE_HOME")
        const base = (xdgCache && xdgCache.length > 0) ? xdgCache : (Quickshell.env("HOME") + "/.cache")
        return base + "/ndotshell/matugen/lock-colors.json"
    }

    // The lockscreen's own picture: the same scheme and contrast as the desktop, but its own
    // first colour (the seed is an index into the DESKTOP wallpaper's colours).
    Process {
        id: lockMatugenProc

        property string pending: ""

        function run(path) {
            if (lockMatugenProc.running) {
                lockMatugenProc.pending = path
                return
            }
            lockMatugenProc.pending = ""
            lockMatugenProc.exec(["sh", root.matugenScript, "apply", path, root.matugenType, "lock-colors"].concat(MG.applyArgs(-1, root.matugenContrast)))
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.log("[ThemeService] matugen (lockscreen):", text.trim())
            }
        }

        onExited: (exitCode, exitStatus) => {
            console.log("[ThemeService] matugen (lockscreen) finished, exit code", exitCode)
            if (exitCode === 0)
                lockColorsFile.reload()
            else
                root.lockMatugenFor = ""
            if (lockMatugenProc.pending !== "") {
                const path = lockMatugenProc.pending
                lockMatugenProc.pending = ""
                lockMatugenProc.exec(["sh", root.matugenScript, "apply", path, root.matugenType, "lock-colors"].concat(MG.applyArgs(-1, root.matugenContrast)))
            }
        }
    }

    // Whatever is there at startup (instant lockscreen colours), and again
    // whenever matugen rewrites it.
    FileView {
        id: lockColorsFile
        path: root.lockMatugenPath
        watchChanges: true
        onFileChanged: lockColorsFile.reload()
        onLoaded: {
            const raw = lockColorsFile.text()
            if (raw === root.lockMatugenRaw)
                return
            try {
                const d = JSON.parse(raw)
                if (root.buildMatugenPalette(d) === null)
                    return
                root.lockMatugenRaw = raw
                root.lockMatugenColors = d
            } catch (e) {
                console.log("[ThemeService] couldn't parse", root.lockMatugenPath, e)
            }
        }
    }

    function cycle() {
        root.setTheme(root.groups[(root.index + 1) % root.groups.length].id)
    }

    // ===== the picker =====
    function togglePicker() {
        if (EditMode.active) {
            if (EditMode.currentTab === "theme")
                EditMode.close()
            else
                EditMode.showTab("theme")
            return
        }
        EditMode.open("", "theme")
    }

    function openPicker() {
        if (!EditMode.active)
            EditMode.open("", "theme")
        else if (EditMode.currentTab !== "theme")
            EditMode.showTab("theme")
    }

    function closePicker() {
        if (EditMode.active && EditMode.currentTab === "theme")
            EditMode.close()
    }

    // ===== Discord theme =====
    property bool discordSync: true

    // Which colours the Discord theme (look=material) wears:
    //   false (default)  it follows the active shell theme: a group theme gives
    //                    Discord that group's colours, "Wallpaper (matugen)" gives
    //                    it matugen's colours.
    //   true             Discord always uses matugen's colours from the wallpaper,
    //                    whichever shell theme is active (matugen then runs on every
    //                    wallpaper change; the shell's own colours don't change).
    property bool discordMatugen: false

    // auto: follow Discord's own light/dark setting (dark = the theme's deep
    // colour). "dark" or "light" force one whatever Discord is set to.
    property string discordMode: "auto"

    readonly property string discordScript: Directories.script("theming/discord-theme.sh")

    function discordArgs() {
        const p = root.palette
        const keys = ["border", "A", "B", "deep", "hoverTint", "divider", "boardBg", "boardDot", "rimHi"]
        const useMatugen = root.current === "matugen" || root.discordMatugen
        const out = ["mode=" + root.discordMode, "source=" + (useMatugen ? "matugen" : "theme")]
        for (let i = 0; i < keys.length; i++) {
            const v = p[keys[i]]
            if (v !== undefined && v !== null)
                out.push(keys[i] + "=" + Qt.color(v).toString())
        }
        return out
    }

    // The palette changes in bursts at startup (default -> saved theme ->
    // matugen colours read from disk), so wait for it to settle first.
    Timer {
        id: discordDebounce
        interval: 700
        onTriggered: {
            if (root.discordSync) {
                root.regenerate("", false)
                discordProc.run(root.discordArgs())
            }
        }
    }

    onPaletteChanged: { discordDebounce.restart(); systemDebounce.restart() }
    onMatugenColorsChanged: discordDebounce.restart()
    onDarkChanged: systemDebounce.restart()
    onDarkTouchedChanged: systemDebounce.restart()
    Component.onCompleted: { root.bootCustom(); root.bootSaved(); discordDebounce.restart(); systemDebounce.restart(); root.checkSystem(); root.regenerateLock(false) }

    // Same queue-one-behind convention as the other Processes here.
    Process {
        id: discordProc

        property var pending: null

        function run(args) {
            if (discordProc.running) {
                discordProc.pending = args
                return
            }
            discordProc.pending = null
            discordProc.exec(["sh", root.discordScript, "write"].concat(args))
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.log("[ThemeService] discord:", text.trim())
            }
        }

        onExited: {
            if (discordProc.pending !== null) {
                const args = discordProc.pending
                discordProc.pending = null
                discordProc.exec(["sh", root.discordScript, "write"].concat(args))
            }
        }
    }

    // ===== System-wide GTK / Qt / KDE colours =====
    // All of these follow Settings > Desktop > System colours.
    readonly property bool systemSync: SettingsService.flag("systemTheme.sync")

    readonly property string systemTargets: {
        const t = []
        if (SettingsService.flag("systemTheme.gtk"))
            t.push("gtk")
        if (SettingsService.flag("systemTheme.qt"))
            t.push("qt")
        if (SettingsService.flag("systemTheme.kde"))
            t.push("kde")
        return t.join(",")
    }

    // Which palette role seeds the scheme for the group themes (A = the main accent;
    // try "B" or "border" for another hue). Not used for the matugen theme.
    property string systemSeedKey: "A"

    // Switch GNOME's gtk-theme to adw-gtk3 / adw-gtk3-dark when adw-gtk3 is installed.
    property bool systemSetGtkTheme: true

    // "Update open apps live": which apps are nudged to repaint after every apply
    readonly property string systemReload: SettingsService.flag("systemTheme.live") ? "gtk3,gtk4,qt,kde" : ""

    // GTK4/libadwaita apps in dark mode only repaint through a quick light/dark switch (a short flash)
    readonly property bool systemBounceDark: SettingsService.flag("systemTheme.bounceDark")

    // What stops apps following (from `system-theme.sh hints`): [{short, long}]
    property var systemHints: []

    // True while system-theme.sh is running, plus a short settle after it. Its
    // GTK4 live reload briefly flips GNOME's color-scheme to the opposite value
    // and back (a ~0.25s bounce), so anything following that setting (the
    // gsettings monitor in UtilButtons.qml) must ignore it meanwhile, or the
    // whole shell flashes light for a moment on every theme / colour change.
    readonly property bool systemBusy: systemProc.running || systemSettle.running

    Timer {
        id: systemSettle
        interval: 700
    }

    function checkSystem() {
        if (hintsProc.running)
            return
        hintsProc.exec(["sh", root.systemScript, "hints"])
    }

    function setSystemSync(on) {
        SettingsService.set("systemTheme.sync", on)
    }

    readonly property string systemScript: Directories.script("theming/system-theme.sh")

    // The arguments for system-theme.sh, or null if there is nothing to run yet
    // (the matugen theme before the wallpaper has been restored).
    function systemArgs(force) {
        const out = []
        if (root.current === "matugen") {
            const img = WallpaperService.imagePath
            if (img === "")
                return null
            out.push("source=image", "value=" + img)
        } else {
            const seed = root.palette[root.systemSeedKey] || root.palette.A
            if (seed === undefined || seed === null)
                return null
            out.push("source=color", "value=" + Qt.color(seed).toString())
        }
        out.push("mode=" + (root.dark ? "dark" : "light"),
                 // A grey seed under the normal tonal-spot scheme still comes out
                 // faintly coloured; matugen's own monochrome scheme is truly grey.
                 "type=" + ((root.current !== "matugen" && root.palette.mono === true) ? "scheme-monochrome" : root.matugenType),
                 "targets=" + root.systemTargets,
                 "gtktheme=" + (root.systemSetGtkTheme ? "on" : "off"),
                 "reload=" + (root.systemReload === "" ? "off" : root.systemReload),
                 "bouncedark=" + (root.systemBounceDark ? "on" : "off"),
                 // Until the mode has come from the real system setting or a click,
                 // `dark` is only the default: don't write GNOME's color-scheme from it.
                 "scheme=" + (root.darkTouched ? "on" : "off"))
        if (force)
            out.push("force=1")
        return out
    }

    function runSystem(force) {
        if (!root.systemSync || !SettingsService.loaded || root.systemTargets === "")
            return
        const args = root.systemArgs(force)
        if (args !== null)
            systemProc.run(args)
    }

    // Colours change in bursts at startup (default -> saved theme -> restored
    // wallpaper -> matugen's colours), so wait for them to settle. The script itself
    // skips a run when nothing changed since the last one.
    Timer {
        id: systemDebounce
        interval: 900
        onTriggered: root.runSystem(false)
    }

    // Settings were loaded from disk: apply once with what the person chose
    Connections {
        target: SettingsService
        function onLoadedChanged() {
            if (SettingsService.loaded) {
                systemDebounce.restart()
                root.checkSystem()
            }
        }
    }

    // A switch in Settings: on = apply now, off = take our colours off again
    onSystemSyncChanged: {
        if (!SettingsService.loaded)
            return
        if (root.systemSync) {
            systemDebounce.restart()
        } else {
            systemDebounce.stop()
            systemRevertProc.running = true
        }
    }
    // Targets or the live switch changed: apply again (the stamp includes the targets)
    onSystemTargetsChanged: if (SettingsService.loaded) systemDebounce.restart()
    onSystemReloadChanged: if (SettingsService.loaded) systemDebounce.restart()

    Process {
        id: hintsProc

        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const raw of text.split("\n")) {
                    const line = raw.trim()
                    if (line === "")
                        continue
                    const i = line.indexOf(" :: ")
                    out.push(i < 0 ? { short: line, long: line }
                                   : { short: line.slice(0, i), long: line.slice(i + 4) })
                }
                root.systemHints = out
                for (const h of out)
                    console.log("[ThemeService] system hint:", h.short, "-", h.long)
            }
        }
    }

    // Same queue-one-behind convention as the other Processes here.
    Process {
        id: systemProc

        property var pending: null

        function run(args) {
            if (systemProc.running) {
                systemProc.pending = args
                return
            }
            systemProc.pending = null
            systemProc.exec(["sh", root.systemScript, "apply"].concat(args))
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.log("[ThemeService] system:", text.trim())
            }
        }

        onExited: (exitCode, exitStatus) => {
            systemSettle.restart()
            if (exitCode === 127)
                console.log("[ThemeService] system: matugen is not installed, GTK/Qt/KDE colours not applied")
            else if (exitCode !== 0)
                console.log("[ThemeService] system: system-theme.sh exited with", exitCode)
            if (systemProc.pending !== null) {
                const args = systemProc.pending
                systemProc.pending = null
                systemProc.exec(["sh", root.systemScript, "apply"].concat(args))
            }
        }
    }

    Process {
        id: systemRevertProc
        command: ["sh", root.systemScript, "revert"]
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.log("[ThemeService] system:", text.trim())
            }
        }
    }

    // ===== persistence =====
    readonly property string script: Directories.script("state/theme-state.sh")

    // Runs once, at startup.
    Process {
        running: true
        command: ["sh", root.script, "load"]
        stdout: StdioCollector {
            onStreamFinished: {
                const id = text.trim()
                if (!root.touched && root.has(id))
                    root.current = id
                root.themeLoaded = true
            }
        }
    }

    // Dark mode, restored at startup (unless it was already changed).
    Process {
        running: true
        command: ["sh", root.script, "load-dark"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim()
                if (!root.darkTouched && (v === "on" || v === "off"))
                    root.dark = (v === "on")
            }
        }
    }

    // The dark look (dark / darker), restored at startup.
    Process {
        running: true
        command: ["sh", root.script, "load-darker"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim()
                if (!root.darkerTouched && (v === "on" || v === "off"))
                    root.darkerPref = (v === "on")
            }
        }
    }

    Process {
        id: darkerSaver

        property string pending: ""

        function save(on) {
            const v = on ? "on" : "off"
            if (darkerSaver.running) {
                darkerSaver.pending = v
                return
            }
            darkerSaver.pending = ""
            darkerSaver.exec(["sh", root.script, "save-darker", v])
        }

        onExited: {
            if (darkerSaver.pending !== "") {
                const v = darkerSaver.pending
                darkerSaver.pending = ""
                darkerSaver.exec(["sh", root.script, "save-darker", v])
            }
        }
    }

    Process {
        id: darkSaver

        property string pending: ""

        function save(on) {
            const v = on ? "on" : "off"
            if (darkSaver.running) {
                darkSaver.pending = v
                return
            }
            darkSaver.pending = ""
            darkSaver.exec(["sh", root.script, "save-dark", v])
        }

        onExited: {
            if (darkSaver.pending !== "") {
                const v = darkSaver.pending
                darkSaver.pending = ""
                darkSaver.exec(["sh", root.script, "save-dark", v])
            }
        }
    }

    Process {
        id: saver

        property string pending: ""

        function save(id) {
            if (saver.running) {
                saver.pending = id
                return
            }
            saver.pending = ""
            saver.exec(["sh", root.script, "save", id])
        }

        onExited: {
            if (saver.pending !== "") {
                const id = saver.pending
                saver.pending = ""
                saver.exec(["sh", root.script, "save", id])
            }
        }
    }

    IpcHandler {
        target: "theme"

        function toggle(): void {
            root.togglePicker()
        }

        function open(): void {
            root.openPicker()
        }

        function close(): void {
            root.closePicker()
        }

        function set(id: string): void {
            root.setTheme(id)
        }

        // Modes: `modeCycle`, `modeSet light|dark|darker`, `modeGet`.
        function modeCycle(): void {
            root.cycleMode()
        }

        function modeSet(id: string): void {
            root.setMode(id)
        }

        function modeGet(): string {
            return root.mode
        }

        // Dark mode: `darkToggle`, `darkOn`, `darkOff`, `darkGet`.
        function darkToggle(): void {
            root.toggleDark()
        }

        function darkOn(): void {
            root.setDark(true)
        }

        function darkOff(): void {
            root.setDark(false)
        }

        function darkGet(): string {
            return root.dark ? "on" : "off"
        }

        function cycle(): void {
            root.cycle()
        }

        // Re-run matugen on the current wallpaper (after changing
        // matugenType, or if it failed the first time).
        function refresh(): void {
            root.regenerate("", true)
            root.regenerateLock(true)
        }

        // Rewrite the Discord theme file with the current palette.
        function discord(): void {
            discordProc.run(root.discordArgs())
        }

        // GTK / Qt / KDE colours (see "System-wide GTK / Qt / KDE colours").
        function system(): void {
            root.setSystemSync(true)
            systemDebounce.stop()
            root.runSystem(true)
        }

        function systemOn(): void {
            root.setSystemSync(true)
        }

        function systemOff(): void {
            root.setSystemSync(false)
        }

        function systemCheck(): void {
            root.checkSystem()
        }

        function get(): string {
            return root.current
        }

        function list(): string {
            return root.groups.map(g => g.id).join(" ")
        }

        // A monitor's own theme (needs theme.perMonitor on); "" (or the main monitor's) to
        // follow the main monitor again.
        function screen(name: string, id: string): void {
            root.setScreenTheme(name, id)
        }

        // What each monitor wears: "DP-2=vs remote=mmj".
        function screens(): string {
            return Quickshell.screens.map(sc => sc.name + "=" + root.themeFor(sc.name)).join(" ")
        }
    }
}
