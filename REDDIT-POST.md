# Reddit post — listo para copiar (r/unixporn)

**Cuándo:** domingo entre 14:00–18:00 UTC (máximo tráfico)
**Flair:** `OC` · **Título exacto:**

```
[OC] NdotShell — Nothing OS-style desktop for Hyprland with double-tap elastic drawers
```

**Cuerpo del post (en inglés, Reddit es inglés):**

---

**NdotShell** — a Nothing OS-styled Quickshell desktop for Hyprland. Everything you see animates with elastic (OutElastic) easing and stays glued to its corner while it wobbles.

**The gimmick:** double-tap a screen corner and the drawer pops out gelatinously:
- **Top-right** → Gaming drawer (animated CPU fan, screen recorder, CPU/RAM meters)
- **Top-left** → Focus drawer (Pomodoro with persistent stats, a typing octopus 🐙)
- **Mid-right** → Dynamic Island (spinning black hole with an orbiting satellite, quick toggles)
- **Bottom-right** → Music dock (spinning vinyl with real album art, transport, volume)

**Also:**
- Quick Panel rendered as a 2.5D hologram phone with scanlines and accent-lit extrusion
- Privacy-first clipboard: secrets (passwords/tokens/cards) are never recorded, history lives in RAM only, auto-wipes on lock, private mode pauses capture (Super+P)
- 6 accent channels: red · mono · amber · lime · blue · violet — the design never changes
- Time-based dynamic wallpaper + auto dark/light theme by hour
- Updates without reinstalling (stable/dev channels, one click in Settings)
- Idle CPU: ~2%

**Install (Arch/CachyOS/EndeavourOS):**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/OptiJK181/NdotShell/main/get.sh) --yes
```

**Repo:** https://github.com/OptiJK181/NdotShell

---

*Base is a fork of SekaiPop by Blapples (GPL-3.0), fully reskinned into a Nothing OS theme with new drawers, island, hologram panel and services. Terminal: kitty · GTK theme: nothing · Icons: Solar · Font: Ndot 55 + Google Sans Flex.*

---

## Checklist del día del post

1. [ ] Subir `docs/social-preview.png` a GitHub: **Settings → General → Social preview** (arrastra la imagen, 30 seg)
2. [ ] Post en r/unixporn con el título de arriba + el GIF como primer media
3. [ ] Cross-post inmediato a r/hyprland y r/quickshell
4. [ ] Responder TODOS los comentarios en las primeras 3 horas
5. [ ] Si alguien pregunta "how do I install" → responde con el one-liner
6. [ ] Twittear/Shares con el GIF: "my Nothing OS desktop for Hyprland"

## Después (semana 1)

- PR a listas awesome: `awesome-hyprland`, `awesome-quickshell` (una línea + GIF)
- Video de 20s vertical para TikTok/Shorts (el mismo mkv de /tmp/opencode/demo/demo.mkv sirve de base)
- Si el post supera 200 upvotes → anunciar v2.4 con lo que salga de los comentarios
