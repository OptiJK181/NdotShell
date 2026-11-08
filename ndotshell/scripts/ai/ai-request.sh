#!/bin/sh

# ai-request.sh — the AI widget's only door to the network.
#
#   sh ai-request.sh <provider> <model> <baseUrl> <temperature> <maxTokens> <systemPrompt>
#
# Reads the conversation (a JSON array of {role, content}) from stdin and
# writes the provider's raw stream to stdout, one event per line:
#
#   openai-family  SSE    data: {"choices":[{"delta":{"content":"..."}}]}
#                  openai · nvidia · openrouter · groq · deepseek ·
#                  mistral · lmstudio all speak this same shape
#   anthropic      SSE    data: {"type":"content_block_delta","delta":{"text":"..."}}
#   ollama         NDJSON {"message":{"content":"..."},"done":false}
#   opencode       NDJSON {"type":"text","part":{"text":"..."}}
#                  (your own opencode CLI: no key, no URL)
#
# The API key is read from ~/.config/ndotshell/ai.json here, so it never
# appears in this process' argv (visible with `ps`) or in the QML layer.
#
# Errors are emitted as one JSON line: {"__ndot_error":"..."} so the widget
# can show a real message instead of a silent failure.
#
#   echo '[{"role":"user","content":"hi"}]' | sh ai-request.sh openai ...
#
# Tested against a mock server in the dev notes (no key needed):
#   NDOT_AI_CONFIG=/tmp/ai.json  (see ai-store.sh)

provider="$1"
model="$2"
base="$3"
temp="$4"
max="$5"
sys="$6"

cfg="${NDOT_AI_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/ndotshell/ai.json}"
key=""
[ -f "$cfg" ] && key=$(jq -r '.apiKey // empty' "$cfg" 2>/dev/null)

# One line of JSON comes in on stdin (JSON.stringify never adds newlines);
# read just that line instead of waiting for EOF, because Quickshell keeps
# the pipe open while the request runs.
IFS= read -r msgs
[ -n "$msgs" ] || msgs='[]'
base=${base%/}

# emit an error line and exit 0: the widget owns the failure UI, a non-zero
# exit here would only be logged as a broken pipe.
fail() {
    printf '%s' "$1" | jq -Rsc '{__ndot_error: .}' 2>/dev/null ||
        printf '{"__ndot_error":"request failed"}\n'
    exit 0
}

need_key() {
    [ -n "$key" ] || fail "Falta la API key. Ajustes → Inteligencia Artificial."
}

case "$provider" in
openai|nvidia|openrouter|groq|deepseek|mistral|lmstudio)
    # One wire for every OpenAI-shaped provider. LM Studio is local and
    # serves without auth; the rest want a key.
    case "$provider" in
    lmstudio) ;;
    *) need_key ;;
    esac
    body=$(jq -n --arg m "$model" --argjson msgs "$msgs" \
        --argjson t "$temp" --argjson mx "$max" \
        '{model:$m, messages:$msgs, stream:true, temperature:$t, max_tokens:$mx}') \
        || fail "No pude construir el cuerpo JSON"
    curl -sS -N --connect-timeout 10 --max-time 180 --fail-with-body \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $key" \
        -H "HTTP-Referer: https://github.com/OptiJK181/NdotShell" \
        -H "X-Title: NdotShell" \
        -d "$body" "$base/chat/completions"
    ;;
anthropic)
    need_key
    body=$(jq -n --arg m "$model" --arg sys "$sys" --argjson msgs "$msgs" \
        --argjson t "$temp" --argjson mx "$max" \
        '{model:$m, max_tokens:$mx, system:$sys, messages:$msgs, stream:true, temperature:$t}') \
        || fail "No pude construir el cuerpo JSON"
    curl -sS -N --connect-timeout 10 --max-time 180 --fail-with-body \
        -H "Content-Type: application/json" \
        -H "x-api-key: $key" \
        -H "anthropic-version: 2023-06-01" \
        -d "$body" "$base/v1/messages"
    ;;
ollama)
    # Local: no key needed (a remote Ollama with auth can be reached
    # through the openai provider instead).
    body=$(jq -n --arg m "$model" --argjson msgs "$msgs" --argjson t "$temp" \
        '{model:$m, messages:$msgs, stream:true, options:{temperature:$t}}') \
        || fail "No pude construir el cuerpo JSON"
    curl -sS -N --connect-timeout 10 --max-time 300 --fail-with-body \
        -H "Content-Type: application/json" \
        -d "$body" "$base/api/chat"
    ;;
opencode)
    # The opencode CLI already knows how to reach its own providers: no key,
    # no URL. Each message is a one-shot archived session and the whole
    # conversation rides inside the prompt.
    command -v opencode >/dev/null 2>&1 \
        || fail "opencode no está instalado (o no está en el PATH del shell)"
    [ -n "$model" ] || fail "Falta el modelo: elige uno con opencode models, p. ej. opencode/big-pickle"
    prompt=$(printf '%s' "$msgs" | jq -r '
        map(if .role == "user" then "Usuario: " + .content
            else "Asistente: " + .content end)
        | join("\n\n")' 2>/dev/null) \
        || fail "No pude armar el prompt para opencode"
    [ -n "$sys" ] && prompt="$sys

---

$prompt"
    errf=$(mktemp)
    # stdin from /dev/null: opencode reads stdin when it is a pipe (that is
    # how it takes piped messages), and Quickshell never closes the pipe it
    # hands this script — opencode would wait for EOF forever.
    timeout 240 opencode run --format json --model "$model" \
        --title "NdotShell AI widget" --archived "$prompt" </dev/null 2>"$errf"
    code=$?
    if [ "$code" -ne 0 ]; then
        why=$(head -c 300 "$errf" | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [ "$code" -eq 124 ] && why="expiró a los 240 s"
        [ -z "$why" ] && why="salió con código $code"
        fail "opencode: $why"
    fi
    rm -f "$errf"
    ;;
*)
    fail "Proveedor desconocido: $provider"
    ;;
esac

code=$?
[ "$code" -ne 0 ] && fail "La petición falló (curl $code). Revisa URL, clave, modelo y red."
exit 0
