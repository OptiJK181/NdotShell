#!/bin/sh

# ai-models.sh — what can this provider run?
#
#   sh ai-models.sh <provider> <baseUrl>
#
# Prints one compact JSON line:
#   {"models":["gpt-4o-mini",...]}
#   {"__ndot_error":"..."}
#
# The API key is read from ~/.config/ndotshell/ai.json (never an argv
# argument). The ids come back in the provider's own order, ready for the
# model picker in Ajustes.

provider="$1"
base="$2"
cfg="${NDOT_AI_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/ndotshell/ai.json}"
key=""
[ -f "$cfg" ] && key=$(jq -r '.apiKey // empty' "$cfg" 2>/dev/null)
base=${base%/}

fail() {
    printf '%s' "$1" | jq -Rsc '{__ndot_error: .}' 2>/dev/null ||
        printf '{"__ndot_error":"could not list models"}\n'
    exit 0
}

# The useful bit of a curl error: the provider's message if it is JSON,
# otherwise the first 200 characters of whatever came back.
short_err() {
    printf '%s' "$1" | jq -r 'try (.error.message // .error // .message // .) catch .' 2>/dev/null |
        head -c 200 | tr '\n' ' '
}

case "$provider" in
openai|nvidia|openrouter|groq|deepseek|mistral|lmstudio|glm)
    # All the OpenAI-shaped ones: GET /models, ids under .data[].id.
    case "$provider" in
    lmstudio) ;;
    *) [ -n "$key" ] || fail "Falta la API key. Ajustes → Inteligencia Artificial." ;;
    esac
    resp=$(curl -sS --max-time 20 --fail-with-body \
        -H "Authorization: Bearer $key" "$base/models" 2>&1)
    rc=$?
    [ "$rc" -ne 0 ] && fail "$(short_err "$resp")"
    printf '%s' "$resp" | jq -c '{models: [(.data // .models // [])[] | (.id // .name // empty)]}' 2>/dev/null \
        || fail "No entendí la respuesta de $base/models"
    ;;
anthropic)
    [ -n "$key" ] || fail "Falta la API key. Ajustes → Inteligencia Artificial."
    resp=$(curl -sS --max-time 20 --fail-with-body \
        -H "x-api-key: $key" -H "anthropic-version: 2023-06-01" "$base/v1/models" 2>&1)
    rc=$?
    [ "$rc" -ne 0 ] && fail "$(short_err "$resp")"
    printf '%s' "$resp" | jq -c '{models: [(.data // .models // [])[] | (.id // .name // empty)]}' 2>/dev/null \
        || fail "No entendí la respuesta de $base/v1/models"
    ;;
ollama)
    # Local: whatever is pulled.
    resp=$(curl -sS --max-time 8 --fail-with-body "$base/api/tags" 2>&1)
    rc=$?
    [ "$rc" -ne 0 ] && fail "No llego a Ollama en $base (¿está corriendo?)"
    printf '%s' "$resp" | jq -c '{models: [(.models // [])[] | (.name // .model // empty)]}' 2>/dev/null \
        || fail "No entendí la respuesta de $base/api/tags"
    ;;
opencode)
    # The CLI's own roster, one "provider/model" per line.
    command -v opencode >/dev/null 2>&1 \
        || fail "opencode no está instalado (o no está en el PATH del shell)"
    timeout 30 opencode models 2>/dev/null |
        jq -Rsc '{models: (split("\n") | map(select(length > 0)))}' 2>/dev/null \
        || fail "opencode models falló"
    ;;
*)
    fail "Proveedor desconocido: $provider"
    ;;
esac
exit 0
