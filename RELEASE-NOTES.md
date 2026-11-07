## 🏝️ 1.3.1 — Isla 100% manual + esquinas clicables

### 🐛 El bug que reportaste: no podías interactuar con la barra

Culpable: la **zona hover de la isla** era una franja invisible sobre la
barra que se comía todos sus clics. Eliminada. Y los hotspots de los
drawers cubrían **el borde completo** — ahora son solo la **esquina**
(8 × 210 px) y **empiezan debajo de la barra**: toda la barra y el resto
del borde vuelven a ser tuyos.

### 🏝️ Dynamic Island: 100% manual, como pediste

- **No aparece hasta que la activas**: `Super + Shift + D` o
  `ipc call island toggle`
- Se abre como **tarjeta de tres paneles** con salida gelatinosa
  (OutElastic): **RELOJ** (Ndot 55 + fecha) · **MÚSICA** (título,
  artista, prev/play/next) · **POMODORO/REC** (timer + play · videocam)
- ✕ o **Esc** la cierran · el toggle de Ajustes (side.island) apaga
  también el keybind
- Con la barra oculta, la isla sube a su lugar

### 🖐️ Drawers: doble toque en la esquina (recordatorio)

Primer toque → **pulso** de la línea de acento; segundo toque (≤420 ms)
→ el panel se despliega con el wobble gelatinoso (OutElastic + squash &
stretch desde el borde).

### 🖥️ Edit Desktop → pestaña **TAREAS**

LLAVES **GAMING · FOCUS · HOTSPOTS · ISLAND** — el control completo de
las barras de tareas vive en Edit Desktop y en Ajustes, y siempre
coinciden.

## ⌨️ Chuleta actualizada

| Atajo | Acción |
|---|---|
| **doble toque esquina derecha** | Panel Gaming |
| **doble toque esquina izquierda** | Panel Focus |
| `Super + Shift + G` / `W` | Fijar panel |
| `Super + P` | Modo privado + OSD |
| `Super + Shift + D` | **Dynamic Island** |
| `Esc` | Cerrar lo que esté abierto |

## ✅ Verificación

- **0 errores** en el log · isla: hidden → open → hidden por IPC,
  render de tres paneles confirmado en captura
- Tests: settings 182 defaults · welcome · update-check — verdes
- Estabilidad: settings ↔ update (watchFiles pausado al aplicar),
  GameMode ↔ notificaciones de updates, canal ↔ .source — sin peleas
