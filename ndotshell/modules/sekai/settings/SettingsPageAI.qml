import QtQuick
import qs.services
import qs.modules.common

// Inteligencia Artificial: the one page that configures the AI widget.
// Everything here lives in AiService (services/AiService.qml) and ends up in
// ~/.config/ndotshell/ai.json, mode 600: provider, base URL, model, key,
// system prompt, temperature, max tokens, plus the conversation itself.
//
// The ten providers share four wire formats (scripts/ai/ai-request.sh):
//   OpenAI-shaped  openai · nvidia · openrouter · groq · deepseek ·
//                  mistral · lmstudio
//   Anthropic      claude
//   Ollama         local, no key
//   opencode       the CLI's own providers — no key here; nvidia/* ids ride
//                  on whatever opencode has authenticated (Nvidia, Claude…)
SettingsPage {
    id: page

    readonly property var src: host ? host.source : null

    // The model picker's filter, and the ids that survive it (capped: a Flow
    // of 300 keycaps is nobody's friend).
    property string modelFilter: ""
    readonly property var matchedModels: {
        const all = AiService.availableModels
        const f = modelFilter.trim().toLowerCase()
        return (f === "") ? all : all.filter(m => m.toLowerCase().indexOf(f) !== -1)
    }
    readonly property var filteredModels: matchedModels.slice(0, 80)

    function pickModel(id) {
        AiService.model = id
        page.modelFilter = ""
        if (filterField) filterField.reset()
        AiService.scheduleSave()
    }

    SectionCard {
        id: providerCard
        title: "Proveedor"

        SettingChoice {
            label: "Proveedor"
            sublabel: "Con quién habla el widget"
            current: AiService.provider
            options: [
                { id: "opencode", label: "OpenCode", icon: "terminal" },
                { id: "nvidia", label: "NVIDIA NIM", icon: "developer_board" },
                { id: "openai", label: "OpenAI", icon: "cloud" },
                { id: "anthropic", label: "Anthropic", icon: "auto_awesome" },
                { id: "openrouter", label: "OpenRouter", icon: "alt_route" },
                { id: "groq", label: "Groq", icon: "bolt" },
                { id: "deepseek", label: "DeepSeek", icon: "waves" },
                { id: "mistral", label: "Mistral", icon: "air" },
                { id: "ollama", label: "Ollama", icon: "monitor" },
                { id: "lmstudio", label: "LM Studio", icon: "computer" }
            ]
            onPicked: id => AiService.setProvider(id)
        }

        SettingText {
            visible: AiService.provider !== "opencode"
            label: "Base URL"
            sublabel: {
                const p = AiService.provider
                if (p === "anthropic") return "api.anthropic.com"
                if (p === "ollama") return "127.0.0.1:11434"
                if (p === "lmstudio") return "127.0.0.1:1234/v1"
                return "Termina en /v1"
            }
            value: AiService.baseUrl
            placeholder: AiService.presets[AiService.provider]
                ? AiService.presets[AiService.provider].baseUrl : ""
            onSubmitted: text => {
                AiService.baseUrl = text.trim()
                AiService.scheduleSave()
            }
            onCleared: {
                AiService.baseUrl = AiService.presets[AiService.provider].baseUrl
                AiService.scheduleSave()
            }
        }

        SettingText {
            visible: AiService.needsKey
            label: "API key"
            sublabel: "Se queda en ~/.config/ndotshell/ai.json (modo 600). No la metas en dotfiles ni en backups."
            password: true
            value: AiService.apiKey
            placeholder: AiService.provider === "nvidia" ? "nvapi-…" : "sk-…"
            onSubmitted: text => {
                AiService.apiKey = text.trim()
                AiService.scheduleSave()
            }
            onCleared: {
                AiService.apiKey = ""
                AiService.scheduleSave()
            }
        }
    }

    SectionCard {
        id: modelCard
        title: "Modelo"

        SettingText {
            label: "Modelo"
            sublabel: {
                const p = AiService.provider
                if (p === "opencode") return "Uno de `opencode models` — nvidia/* usa tu Nvidia del CLI"
                if (p === "ollama") return "El que tengas con `ollama pull`"
                if (p === "lmstudio") return "El id exacto del modelo cargado en LM Studio"
                return "El id exacto del modelo"
            }
            value: AiService.model
            placeholder: AiService.presets[AiService.provider]
                ? AiService.presets[AiService.provider].model : ""
            onSubmitted: text => {
                AiService.model = text.trim()
                AiService.scheduleSave()
            }
        }

        SettingAction {
            width: modelCard.innerWidth
            icon: "cloud_download"
            label: "Buscar modelos del proveedor"
            detail: AiService.modelsLoading ? "Buscando…"
                : (AiService.modelsError !== "" ? AiService.modelsError
                : (AiService.availableModels.length > 0
                    ? AiService.availableModels.length + " modelos · toca uno para usarlo"
                    : "Lista los ids que acepta el proveedor"))
            busy: AiService.modelsLoading
            onActivated: AiService.fetchModels()
        }

        SettingText {
            id: filterField
            visible: AiService.availableModels.length > 0
            label: "Filtro"
            sublabel: "Escribe para acotar la lista"
            value: page.modelFilter
            placeholder: "llama, nemotron, gpt…"
            onEdited: text => page.modelFilter = text
            onSubmitted: text => page.modelFilter = text
            onCleared: page.modelFilter = ""
        }

        Flow {
            visible: AiService.availableModels.length > 0
            width: modelCard.innerWidth
            spacing: 12

            Repeater {
                model: page.filteredModels

                delegate: SettingChip {
                    required property var modelData

                    label: modelData
                    selected: AiService.model === modelData
                    onClicked: page.pickModel(modelData)
                }
            }
        }

        Text {
            id: listNote
            property string note: page.matchedModels.length === 0
                ? "Ningún modelo coincide con \"" + page.modelFilter.trim() + "\""
                : (page.matchedModels.length > page.filteredModels.length
                    ? "Mostrando " + page.filteredModels.length + " de " + page.matchedModels.length + " — refina el filtro"
                    : "")
            visible: AiService.availableModels.length > 0 && listNote.note !== ""
            width: modelCard.innerWidth
            text: listNote.note
            color: mt.pInkSub
            font.family: mt.fontFamily
            font.pixelSize: 14
            wrapMode: Text.WordWrap
        }
    }

    SectionCard {
        title: "Conversación"

        SettingText {
            label: "System prompt"
            sublabel: "Cómo debe hablar y qué debe saber"
            value: AiService.systemPrompt
            placeholder: "Eres Ndot, el asistente del escritorio…"
            onSubmitted: text => {
                AiService.systemPrompt = text
                AiService.scheduleSave()
            }
            onCleared: {
                AiService.systemPrompt = ""
                AiService.scheduleSave()
            }
        }

        SettingSlider {
            label: "Temperatura"
            icon: "thermometer"
            value: AiService.temperature
            from: 0
            to: 2
            step: 0.1
            decimals: 1
            onMoved: v => {
                AiService.temperature = v
                AiService.scheduleSave()
            }
        }

        SettingStepper {
            icon: "memory"
            label: "Máx. tokens"
            from: 128
            to: 16384
            step: 128
            value: AiService.maxTokens
            onMoved: v => {
                AiService.maxTokens = Math.round(v)
                AiService.scheduleSave()
            }
        }

        SettingAction {
            icon: "delete"
            label: "Borrar la conversación"
            detail: AiService.messages.length === 0
                ? "No hay nada guardado"
                : AiService.messages.length + " mensajes"
            onActivated: AiService.clear()
        }
    }

    SectionCard {
        title: "Acceso"

        SettingAction {
            icon: "sync"
            label: "Probar conexión"
            detail: AiService.testing
                ? "Comprobando…"
                : (AiService.testResult !== ""
                    ? AiService.testResult
                    : "Hace un GET de modelos: no gasta tokens")
            busy: AiService.testing
            onActivated: AiService.testConnection()
        }

        SettingAction {
            icon: "open_in_new"
            label: "Abrir el chat"
            detail: "El mismo panel del borde derecho"
            onActivated: AiService.open()
        }

        SettingToggle {
            icon: "blur_on"
            label: "Orbe en el escritorio"
            detail: AiService.orbVisible ? "Visible" : "Oculto"
            checked: AiService.orbVisible
            onToggled: AiService.toggleOrbVisible()
        }

        SettingAction {
            icon: "content_copy"
            label: "Copiar un ejemplo de comando"
            detail: "qs -c ndotshell ipc call ai ask \"…\""
            onActivated: AiService.copyCommand()
        }
    }
}
