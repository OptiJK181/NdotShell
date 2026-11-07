# 🖤 NdotShell 2.0.0 — **STABLE OFICIAL**

Primera versión estable. Todo lo de abajo vive en `main` (canal `stable`)
y ha sido verificado en pantalla, con **0 errores** en el log y la suite
de tests completa en verde.

---

## 🕳️ Dynamic Island → menú lateral con agujero negro

La isla se muda al **lateral derecho** (del 40 % al 94 % de altura) y
ahora es un **menú interactivo**: en su cabeza, un **agujero negro
girando** — núcleo negro, disco de acento del canal a 270° girando, y un
satélite en órbita contraria. Debajo, las llaves:

**REC · POMODORO · MÚSICA · PRIVADO · CAPTURA · GAMING · FOCUS**

Se abre con **doble toque en su zona del borde** (o `Super + Shift + D`,
o `ipc call island toggle`), con salida gelatinosa. ✕ o Esc cierran.

## 🎶 Music dock — esquina inferior derecha

**Doble toque en la esquina inferior derecha** (o `Super + Shift + U`)
abre el dock de medios:

- **Vinilo girando** con el **arte real del álbum** (artUrl por MPRIS),
  surcos y agujero central — gira solo mientras suena
- Título (3 líneas) y artista
- Transporte completo: prev / play (acento) / next
- **Volumen** con barra (si el player lo soporta)
- Apertura gelatinosa OutElastic · ✕ / Esc cierran

## 🫠 Drawers: doble toque + gelatina + conexiones

- **Doble toque en la esquina** (der = Gaming, izq = Focus): 1er toque
  hace **pulsar** la línea de acento, 2º (≤420 ms) despliega
- Slide **OutElastic** + **squash & stretch** del panel desde el borde
- El slab nace **justo bajo la barra** y la hairline de acento la toca —
  conectados como Caelestia
- **Aparición escalonada**: cada fila entra con su propio retardo
- 🌀 **Ventilador en GAMING** que gira según la CPU (RPM en Ndot)
- 🐙 **Pulpo escribiendo en FOCUS** que flota, respira y teclea mensajes

## 🖐️ Hotspots por zona

| Zona | Doble toque | Abre |
|---|---|---|
| esquina superior derecha | ×2 | Panel GAMING |
| esquina superior izquierda | ×2 | Panel FOCUS |
| lateral derecho, al medio | ×2 | Isla (agujero negro) |
| esquina inferior derecha | ×2 | **Dock de música** |

El resto de la pantalla queda 100 % clicable, siempre.

## ⚙️ Controles (todo sincronizado)

- **Ajustes → Escritorio → Barras de tareas**: Gaming · Focus ·
  hotspots · Isla · **Dock de música** · Barra superior (quitable)
- **Edit Desktop → TAREAS**: GAMING · FOCUS · HOTSPOTS · ISLAND · MÚSICA
- IPC: `island toggle|show|hide|status` · `musicdock toggle|show|hide|status`

## 🐛 Fixes

- `holeRing`/`holeSat` refs rotos en la isla (ReferenceError)
- `edit_off` sin icono → aliado a `pen-2`
- Zonas de hotspot usan `screen.height` (Quickshell windows no tienen parent)

---

## ⌨️ Chuleta completa

| Atajo | Acción |
|---|---|
| `Super` (tap) | Apps |
| `Super + N` | Quick Panel (teléfono) |
| `Super + I` | Ajustes |
| `Super + /` | Cheat sheet |
| `Super + G` | Game Mode |
| `Super + P` | Modo privado (portapapeles) + OSD |
| `Super + Shift + G` / `W` | Fijar Panel Gaming / Focus |
| `Super + Shift + D` | Dynamic Island (agujero negro) |
| `Super + Shift + U` | Dock de música |
| doble toque en las zonas | Drawers / Isla / Música |
| `Esc` | Cerrar lo abierto |
