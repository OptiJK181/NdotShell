pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// AiService — the AI widget's brain.
//
// One conversation, ten providers, three surfaces (bar key, drawer, desktop
// orb). The network work happens in scripts/ai/ai-request.sh, which also reads
// the API key from disk: the key never touches this process' argv, and the
// QML layer never builds an Authorization header.
//
// The ten providers share four wire formats (scripts/ai/ai-request.sh):
//   OpenAI-shaped  openai · nvidia · openrouter · groq · deepseek ·
//                  mistral · lmstudio
//   Anthropic      claude
//   Ollama         local models
//   opencode       your own opencode CLI — no key here, it uses whatever the
//                  CLI has configured (nvidia/* ids ride on your Nvidia auth)
//
//   qs -c ndotshell ipc call ai ask "explica esto"
//   qs -c ndotshell ipc call ai toggle | open | close | clear | stop | retry
//
// Config + history live in ~/.config/ndotshell/ai.json (mode 600, written
// atomically by scripts/ai/ai-store.sh). It is private: it holds the key and
// everything you have asked.
Singleton {
    id: root

    // ===== providers =====
    // The order here is only the fallback when the settings page lists them;
    // it picks its own order. Every `hint` names where the key comes from.
    readonly property var presets: ({
        opencode: {
            label: "OpenCode (CLI)",
            hint: "Tu opencode configurado · sin key aquí",
            baseUrl: "",
            // Verified working: rides on the Nvidia auth stored in the CLI.
            model: "nvidia/deepseek-ai/deepseek-v4.1-flash"
        },
        nvidia: {
            label: "NVIDIA NIM",
            hint: "build.nvidia.com · nvapi-… · Llama, Nemotron, DeepSeek",
            baseUrl: "https://integrate.api.nvidia.com/v1",
            model: "meta/llama-3.3-70b-instruct"
        },
        openai: {
            label: "OpenAI-compatible",
            hint: "OpenAI o cualquier servidor que hable /v1",
            baseUrl: "https://api.openai.com/v1",
            model: "gpt-4o-mini"
        },
        openrouter: {
            label: "OpenRouter",
            hint: "Cientos de modelos con una sola key",
            baseUrl: "https://openrouter.ai/api/v1",
            model: "openai/gpt-4o-mini"
        },
        groq: {
            label: "Groq",
            hint: "Gratis con límites · rapidísimo",
            baseUrl: "https://api.groq.com/openai/v1",
            model: "llama-3.3-70b-versatile"
        },
        deepseek: {
            label: "DeepSeek",
            hint: "deepseek-chat · deepseek-reasoner",
            baseUrl: "https://api.deepseek.com/v1",
            model: "deepseek-chat"
        },
        mistral: {
            label: "Mistral",
            hint: "La Plateforme",
            baseUrl: "https://api.mistral.ai/v1",
            model: "mistral-small-latest"
        },
        lmstudio: {
            label: "LM Studio (local)",
            hint: "127.0.0.1:1234 · sin key · elige el modelo cargado",
            baseUrl: "http://127.0.0.1:1234/v1",
            model: ""
        },
        anthropic: {
            label: "Anthropic",
            hint: "Claude (api.anthropic.com)",
            baseUrl: "https://api.anthropic.com",
            model: "claude-sonnet-4-5"
        },
        ollama: {
            label: "Ollama (local)",
            hint: "Privado y gratis · 127.0.0.1:11434",
            baseUrl: "http://127.0.0.1:11434",
            model: "llama3.2"
        }
    })

    // ===== saved config =====
    property string provider: "openai"
    property string baseUrl: presets.openai.baseUrl
    property string apiKey: ""
    property string model: presets.openai.model
    property string systemPrompt: "Eres Ndot, el asistente del escritorio NdotShell (Nothing OS sobre Hyprland). Responde claro, breve y en el idioma de la persona. Si no sabes algo, dilo."
    property real temperature: 0.7
    property int maxTokens: 1024
    property bool loaded: false

    // ===== conversation =====
    property var messages: []          // [{ role: "user"|"assistant", content: "..." }]
    property string streamingText: ""
    property bool busy: false
    property string error: ""
    property bool testing: false
    property string testResult: ""
    // The model picker: ids the current provider offers, filled by fetchModels().
    property var availableModels: []
    property bool modelsLoading: false
    property string modelsError: ""

    // ===== the desktop face's mood =====
    // When the last reply landed (the pet keeps its speech bubble up for a
    // while after) and an IPC-pinned mood that wins over the computed one.
    property real lastReplyAt: 0
    property string moodOverride: ""

    // ===== surfaces =====
    property bool drawerOpen: false
    property bool orbOpen: false
    property bool orbVisible: true
    // Where the desktop orb sits (real pixels). -1 = never moved: the orb
    // picks a spot bottom-right on its monitor.
    property real orbX: -1
    property real orbY: -1

    // ===== derived =====
    // opencode and LM Studio are local: no key. Everything else wants one.
    readonly property bool needsKey: provider !== "ollama" && provider !== "opencode" && provider !== "lmstudio"
    readonly property bool configured: model.trim() !== "" && (!needsKey || apiKey.trim() !== "")
    readonly property string providerLabel: presets[provider] ? presets[provider].label : provider
    readonly property var lastAssistant: {
        for (let i = messages.length - 1; i >= 0; i--)
            if (messages[i].role === "assistant") return messages[i]
        return null
    }
    readonly property bool canRetry: !busy && messages.length > 0
        && messages[messages.length - 1].role === "user"

    // ===== scripts =====
    readonly property string requestScript: Directories.script("ai/ai-request.sh")
    readonly property string storeScript: Directories.script("ai/ai-store.sh")
    readonly property string testScript: Directories.script("ai/ai-test.sh")
    readonly property string modelsScript: Directories.script("ai/ai-models.sh")

    // ===== config plumbing =====
    property bool saveDirty: false
    property bool sendPending: false
    property string pendingPayload: ""

    function configObject() {
        return {
            provider: root.provider,
            baseUrl: root.baseUrl,
            apiKey: root.apiKey,
            model: root.model,
            systemPrompt: root.systemPrompt,
            temperature: root.temperature,
            maxTokens: root.maxTokens,
            orbVisible: root.orbVisible,
            orbX: root.orbX,
            orbY: root.orbY,
            messages: root.messages.slice(-60)
        }
    }

    function applyConfig(text) {
        if (!text || text.trim() === "") {
            root.loaded = true
            return
        }
        try {
            const j = JSON.parse(text)
            if (typeof j.provider === "string" && root.presets[j.provider]) root.provider = j.provider
            if (typeof j.baseUrl === "string" && j.baseUrl !== "") root.baseUrl = j.baseUrl
            if (typeof j.apiKey === "string") root.apiKey = j.apiKey
            if (typeof j.model === "string" && j.model !== "") root.model = j.model
            if (typeof j.systemPrompt === "string") root.systemPrompt = j.systemPrompt
            if (typeof j.temperature === "number") root.temperature = j.temperature
            if (typeof j.maxTokens === "number") root.maxTokens = j.maxTokens
            if (typeof j.orbVisible === "boolean") root.orbVisible = j.orbVisible
            if (typeof j.orbX === "number") root.orbX = j.orbX
            if (typeof j.orbY === "number") root.orbY = j.orbY
            if (Array.isArray(j.messages)) {
                root.messages = j.messages
                    .filter(m => m && (m.role === "user" || m.role === "assistant") && typeof m.content === "string")
                    .slice(-60)
            }
        } catch (e) {
            console.warn("AiService: bad ai.json:", e)
        }
        root.loaded = true
    }

    function scheduleSave() {
        root.saveDirty = true
        saveDebounce.restart()
    }

    function saveNow() {
        saveDebounce.stop()
        if (saver.running) {
            // the writer is busy: come back when it finishes
            root.saveDirty = true
            return
        }
        root.pendingPayload = JSON.stringify(root.configObject())
        root.saveDirty = false
        saver.running = true
    }

    Timer {
        id: saveDebounce
        interval: 350
        onTriggered: root.saveNow()
    }

    Process {
        id: saver
        command: ["sh", root.storeScript, "save"]
        stdinEnabled: true
        onStarted: saver.write(root.pendingPayload + "\n")
        onExited: {
            if (root.saveDirty) root.saveNow()
            if (root.sendPending) {
                root.sendPending = false
                root.startRequest()
            }
        }
    }

    Process {
        id: loader
        command: ["sh", root.storeScript, "load"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.applyConfig(text)
        }
        onExited: root.loaded = true
    }

    // ===== provider =====
    function setProvider(id) {
        if (!root.presets[id]) return
        const old = root.presets[root.provider]
        const next = root.presets[id]
        // Move to the new defaults only when the field still holds the old
        // provider's default (or is empty): never overwrite a custom URL/model.
        if (root.baseUrl.trim() === "" || (old && root.baseUrl === old.baseUrl))
            root.baseUrl = next.baseUrl
        if (root.model.trim() === "" || (old && root.model === old.model))
            root.model = next.model
        root.provider = id
        root.testResult = ""
        // A model list belongs to a provider: drop the old one.
        root.availableModels = []
        root.modelsError = ""
        root.scheduleSave()
    }

    // ===== conversation =====
    function send(text) {
        const clean = (text || "").trim()
        if (clean === "" || root.busy) return
        root.error = ""
        root.streamingText = ""
        root.messages = root.messages.concat([{ role: "user", content: clean }])
        if (root.saveDirty || !root.loaded) {
            root.sendPending = true
            root.saveNow()
            return
        }
        root.startRequest()
    }

    function startRequest() {
        if (root.busy) return
        request.command = ["sh", root.requestScript, root.provider, root.model,
            root.baseUrl, String(root.temperature), String(root.maxTokens), root.systemPrompt]
        request.running = true
    }

    Process {
        id: request
        stdinEnabled: true
        stdout: SplitParser { onRead: line => root.handleLine(line) }
        stderr: SplitParser { onRead: line => console.warn("[AI]", line) }
        onStarted: {
            root.busy = true
            root.error = ""
            root.streamingText = ""
            // The script only needs role+content; keep the payload small.
            const wire = root.messages.map(m => ({ role: m.role, content: m.content }))
            request.write(JSON.stringify(wire) + "\n")
        }
        onExited: (code, status) => {
            if (root.busy) root.finishStream(code !== 0 ? "La conexión se cortó (curl " + code + ")" : "")
        }
    }

    function handleLine(raw) {
        let line = (raw || "").trim()
        if (line === "") return
        if (line.startsWith("data:")) line = line.slice(5).trim()
        if (line === "[DONE]") {
            root.finishStream("")
            return
        }
        let j = null
        try { j = JSON.parse(line) } catch (e) { return }
        if (!j) return

        if (typeof j.__ndot_error === "string") {
            root.finishStream(j.__ndot_error)
            return
        }
        if (j.error) {
            const msg = (typeof j.error === "string") ? j.error
                : (j.error.message || JSON.stringify(j.error))
            root.finishStream(msg)
            return
        }

        let delta = ""
        if (root.provider === "anthropic") {
            if (j.type === "content_block_delta" && j.delta) delta = j.delta.text || ""
            else if (j.type === "message_stop") {
                root.finishStream("")
                return
            } else if (j.type === "error") {
                root.finishStream(j.error ? (j.error.message || "Error de Anthropic") : "Error de Anthropic")
                return
            }
        } else if (root.provider === "ollama") {
            if (j.message) delta = j.message.content || ""
            if (j.done === true) {
                root.finishStream("")
                return
            }
        } else if (root.provider === "opencode") {
            // opencode's --format json: step_start / text / step_finish
            // events, and its own errors as {"type":"error"} lines (a spent
            // free limit, an EOL model…). step_* events are ignored.
            if (j.type === "text" && j.part) delta = j.part.text || ""
            else if (j.type === "error") {
                const msg = (typeof j.error === "string") ? j.error
                    : ((j.error && j.error.message) || "Error de opencode")
                root.finishStream(msg)
                return
            }
        } else {
            const c = j.choices && j.choices[0]
            if (c && c.delta) delta = c.delta.content || ""
            else if (c) delta = c.text || ""
        }
        if (delta !== "") root.streamingText += delta
    }

    function finishStream(err) {
        if (!root.busy) return
        root.busy = false
        request.running = false
        root.lastReplyAt = Date.now()
        if (err && err !== "") root.error = err
        const text = root.streamingText
        root.streamingText = ""
        if (text.trim() !== "") {
            root.messages = root.messages.concat([{ role: "assistant", content: text }])
            if (!err || err === "") root.error = ""
        }
        root.scheduleSave()
    }

    function stop() {
        if (!root.busy) return
        root.finishStream("")
    }

    function clear() {
        root.messages = []
        root.streamingText = ""
        root.error = ""
        root.scheduleSave()
    }

    function retry() {
        if (root.busy || root.messages.length === 0) return
        const last = root.messages[root.messages.length - 1]
        if (last.role !== "user") return
        root.error = ""
        root.startRequest()
    }

    function regenerate() {
        if (root.busy) return
        let next = root.messages.slice()
        while (next.length && next[next.length - 1].role === "assistant")
            next.pop()
        if (!next.length || next[next.length - 1].role !== "user") return
        root.messages = next
        root.error = ""
        root.startRequest()
    }

    function copyLast() {
        if (root.lastAssistant)
            Quickshell.execDetached(["wl-copy", root.lastAssistant.content])
    }

    // ===== connection test =====
    function testConnection() {
        if (root.testing) return
        root.testResult = ""
        root.testing = true
        testProc.command = ["sh", root.testScript, root.provider, root.baseUrl, root.model]
        testProc.running = true
    }

    Process {
        id: testProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    root.testResult = j.ok ? ("OK · " + (j.detail || "conectado")) : ("Error · " + (j.error || "sin detalle"))
                } catch (e) {
                    root.testResult = "Error · respuesta inesperada"
                }
                root.testing = false
            }
        }
        onExited: root.testing = false
    }

    // ===== model picker =====
    function fetchModels() {
        if (root.modelsLoading) return
        root.modelsError = ""
        root.modelsLoading = true
        modelsProc.command = ["sh", root.modelsScript, root.provider, root.baseUrl]
        modelsProc.running = true
    }

    Process {
        id: modelsProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.modelsLoading = false
                try {
                    const j = JSON.parse(text)
                    if (Array.isArray(j.models)) {
                        root.availableModels = j.models.filter(m => typeof m === "string" && m.trim() !== "")
                        root.modelsError = root.availableModels.length > 0 ? "" : "El proveedor no devolvió ningún modelo"
                    } else if (typeof j.__ndot_error === "string") {
                        root.availableModels = []
                        root.modelsError = j.__ndot_error
                    } else {
                        root.availableModels = []
                        root.modelsError = "Respuesta inesperada"
                    }
                } catch (e) {
                    root.availableModels = []
                    root.modelsError = "Respuesta inesperada"
                }
            }
        }
        onExited: root.modelsLoading = false
    }

    // ===== the desktop face =====
    // What the pet shows: what the AI is doing first, and — once it answers —
    // what it said. IPC can pin one for a while: `ipc call ai face happy`.
    function setMood(mood, ms) {
        if (root.moodNames.indexOf(mood) === -1) return
        root.moodOverride = mood
        moodClear.interval = ms && ms > 0 ? ms : 8000
        moodClear.restart()
    }

    Timer {
        id: moodClear
        interval: 8000
        onTriggered: root.moodOverride = ""
    }

    readonly property var moodNames: ["neutral", "happy", "sad", "curious", "ouch", "thinking", "talking", "startle", "sleepy"]

    // A tiny word read of the reply: sorry-stuff hurts it, exclamations and
    // good news cheer it up, questions make it curious.
    function moodFromText(t) {
        if (!t || t === "") return "neutral"
        const s = t.toLowerCase()
        const has = words => words.some(w => s.indexOf(w) !== -1)
        const sad = has(["error", "no pude", "lo siento", "perdón", "falló", "fallo",
            "no encontré", "no se pudo", "lamentablemente", "problema", "⚠"])
        const happy = has(["genial", "perfecto", "excelente", "listo", "hecho", "claro",
            "disfruta", "❤", "😊", "🎉", "✅", "😄", "😀", "👍", "🚀", "💪", "great", "amazing"])
        const exclaims = (t.match(/[!¡]/g) || []).length
        const asks = (t.match(/[?¿]/g) || []).length
        if (sad) return "sad"
        if (happy || exclaims >= 2) return "happy"
        if (asks >= 2) return "curious"
        return "neutral"
    }

    readonly property string faceMood: moodOverride !== "" ? moodOverride
        : (error !== "" ? "ouch"
        : (streamingText !== "" ? "talking"
        : (busy ? "thinking"
        : moodFromText(lastAssistant ? lastAssistant.content : ""))))

    // ===== surfaces =====
    function toggle() { root.drawerOpen = !root.drawerOpen }
    function open() { root.drawerOpen = true }
    function close() { root.drawerOpen = false }
    // orbOpen: the desktop orb expanded into the chat card.
    function toggleOrb() { root.orbOpen = !root.orbOpen }
    // orbVisible: whether the orb exists on the desktop at all.
    function toggleOrbVisible() {
        root.orbVisible = !root.orbVisible
        if (!root.orbVisible) root.orbOpen = false
        root.scheduleSave()
    }

    function setOrbPos(x, y) {
        root.orbX = Math.round(x)
        root.orbY = Math.round(y)
        root.scheduleSave()
    }

    function copyCommand() {
        Quickshell.execDetached(["wl-copy", "qs -c ndotshell ipc call ai ask \"¿qué puedo hacer con NdotShell?\""])
    }

    function ask(text) {
        root.open()
        root.send(text)
    }
}
