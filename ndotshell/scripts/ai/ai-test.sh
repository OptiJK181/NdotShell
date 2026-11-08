#!/bin/sh

# ai-test.sh — "is this provider reachable and is my key good?"
#
#   sh ai-test.sh <provider> <baseUrl> <model>
#
# The key is read from ~/.config/ndotshell/ai.json (never an argv argument).
# Prints one compact JSON line:
#   {"ok":true,"detail":"HTTP 200 · 12 modelos"}
#   {"ok":false,"error":"invalid api key"}
#
# It only lists models (a GET): no tokens are spent.

provider="$1"
base="$2"
model="$3"
cfg="${NDOT_AI_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/ndotshell/ai.json}"
key=""
[ -f "$cfg" ] && key=$(jq -r '.apiKey // empty' "$cfg" 2>/dev/null)
base=${base%/}

emit_ok() { jq -nc --arg d "$1" '{ok:true, detail:$d}'; exit 0; }
emit_err() {
    jq -nc --arg e "$1" '{ok:false, error:$e}' 2>/dev/null ||
        printf '{"ok":false,"error":"request failed"}\n'
    exit 0
}

short_err() {
    printf '%s' "$1" | jq -r 'try (.error.message // .error // .message // .) catch .' 2>/dev/null |
        head -c 240 | tr '\n' ' '
}

case "$provider" in
openai|nvidia|openrouter|groq|deepseek|mistral|lmstudio)
    case "$provider" in
    lmstudio) ;;
    *) [ -n "$key" ] || emit_err "Falta la API key" ;;
    esac
    resp=$(curl -sS --max-time 15 --fail-with-body -w '\n%{http_code}' \
        -H "Authorization: Bearer $key" "$base/models" 2>&1)
    rc=$?
    ;;
anthropic)
    [ -n "$key" ] || emit_err "Falta la API key"
    resp=$(curl -sS --max-time 15 --fail-with-body -w '\n%{http_code}' \
        -H "x-api-key: $key" -H "anthropic-version: 2023-06-01" \
        "$base/v1/models" 2>&1)
    rc=$?
    ;;
ollama)
    resp=$(curl -sS --max-time 8 --fail-with-body -w '\n%{http_code}' \
        "$base/api/tags" 2>&1)
    rc=$?
    ;;
opencode)
    # No network from us: the CLI answers for its own configured providers.
    command -v opencode >/dev/null 2>&1 \
        || emit_err "opencode no está instalado (o no está en el PATH)"
    list=$(timeout 30 opencode models 2>/dev/null) || emit_err "opencode models falló"
    n=$(printf '%s\n' "$list" | grep -c .)
    [ "$n" -gt 0 ] || emit_err "opencode models no devolvió ningún modelo"
    if [ -n "$model" ] && ! printf '%s\n' "$list" | grep -qxF "$model"; then
        emit_err "CLI ok, pero \"$model\" no está en opencode models"
    fi
    emit_ok "CLI ok · $n modelos"
    ;;
*)
    emit_err "Proveedor desconocido: $provider"
    ;;
esac

code=$(printf '%s' "$resp" | tail -n1)
body=$(printf '%s' "$resp" | sed '$d')

if [ "$rc" -ne 0 ]; then
    msg=$(short_err "$body")
    [ -z "$msg" ] && msg="No se pudo conectar (curl $rc). Revisa la URL y la red."
    emit_err "$msg"
fi

case "$provider" in
openai|anthropic|nvidia|openrouter|groq|deepseek|mistral|lmstudio)
    n=$(printf '%s' "$body" | jq -r '(.data // .models // []) | length' 2>/dev/null || echo 0)
    emit_ok "HTTP $code · $n modelos"
    ;;
ollama)
    n=$(printf '%s' "$body" | jq -r '(.models // []) | length' 2>/dev/null || echo 0)
    if [ "$n" -eq 0 ]; then
        emit_err "Responde, pero no hay modelos instalados (ollama pull $model)"
    fi
    emit_ok "HTTP $code · $n modelos"
    ;;
esac
