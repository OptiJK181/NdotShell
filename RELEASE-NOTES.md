## 🎮 Side drawers 100% destinados: Gaming + Focus (ofimática)

Dos paneles laterales con slide-in, estilo Nothing (slab negro, 1 px rim,
Ndot 55), un panel abierto a la vez, click fuera o Esc para cerrar.

### Panel GAMING — borde derecho — `Super + Shift + G`
- **Game Mode** (rendimiento arriba, avisos fuera) — un tap
- **Grabadora** con timer en vivo (toca para grabar / detener)
- **Avisos** on/off (DND para jugar)
- **Keep Awake** (la pantalla no se apaga en partida larga)
- **Medidores CPU/RAM** en vivo (solo muestrean con el panel abierto)

### Panel FOCUS (ofimática) — borde izquierdo — `Super + Shift + W`
- **Pomodoro** con timer Ndot 55: play/pausa, saltar, reset, ciclos y
  minutos de hoy (persisten entre reinicios)
- **Focus Mode** (los widgets se apartan mientras trabajas)
- **Portapapeles privado**: toggle del modo privado + borrar historial

## 🔒 Modo privado con animación — `Super + P`

- **OSD nuevo**: pill con icono visibility_off/visibility y texto
  "Modo privado"; la barra del gauge es el estado (llena = ON).
- La animación sale al togglear desde **cualquier** sitio: keybind,
  tile del drawer, o `ipc call clipboard toggle`.
- Recuerda: los secretos (passwords, tokens, tarjetas, JWTs…) **nunca**
  entran al historial, el modo privado pausa todo, y el historial se
  borra solo al bloquear la pantalla.

## 🛠️ Fixes

- `id is not unique` en DynamicWallpaperService
- `IpcHandler is not a type` (import Quickshell.Io faltante)
- `Directories is not defined` en DynamicWallpaperService
- PomodoroService.running espejado (el id del Timer no era visible fuera)
- Dynamic wallpaper aplica vía WallpaperService directamente

## ⌨️ Resumen de atajos nuevos

| Atajo | Acción |
|---|---|
| `Super + P` | Modo privado (portapapeles) + animación OSD |
| `Super + Shift + G` | Panel Gaming |
| `Super + Shift + W` | Panel Focus (ofimática) |

Todos reasignables en Settings → Hyprland → Keybinds.
