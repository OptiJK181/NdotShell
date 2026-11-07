## 🫧 1.3.0 — Isla automática, doble-tap gelatinoso y tab TAREAS en Edit Desktop

### 🏝️ Dynamic Island: ya no es manual, ahora tiene criterio

- **Oculta por defecto** — la píldora ya no vive ahí molestando sobre
  tus ventanas (lo de tu captura).
- **Se asoma sola** (compacta) solo cuando tiene algo que decir:
  🔴 grabando · 🔵 Pomodoro corriendo · ▶ música sonando
- **Hover en el centro superior** (franja de 34 px bajo la barra) la
  abre expandida desde cualquier estado; **clic la fija**, Esc o
  alejarse la cierra.
- Apertura con **OutElastic** — gelatina pura.

### �atha Drawer Laterales: doble toque + gelatina

- **Ya no se abren por hover** — ahora es **doble toque en la esquina**
  del borde: el primer toque hace **pulsar la línea de acento** (el
  borde responde), el segundo (≤420 ms) despliega.
- La franja del borde tiene 4 estados de opacidad: reposo 12 % · hover
  45 % · pulso 100 % · drawer abierto 85 %.
- **Movimiento líquido gelatinoso**: slide con OutElastic + squash &
  stretch del panel (scale 1.045 → 0.972 → 1.014 → 1.0) desde el borde —
  se siente como gelatina, no como un panel de Windows 95.

### 🖥️ Edit Desktop → nueva pestaña **TAREAS**

Completo lo pendiente: dentro de Edit Desktop hay una pestaña nueva con
llaves **GAMING · FOCUS · HOTSPOTS · ISLAND** (mismo patrón DOCK), junto
a BAR/DOCK/VIEWS/THEME/PRESETS. Ajustes → Barras de tareas sigue
existiendo y ambos siempre coinciden.

### ➕ Barras de tareas: + "Barra superior"

El apartado ahora también tiene el toggle de **bar.visible** — sí, la
barra se puede quitar; si solo quieres la isla, apágala ahí.

## 🐛 Fixes

- Island: `Keys.onEscapePressed` duplicado (Property value set multiple
  times)
- Island: `pill.pinned` → `win.pinned` (la propiedad vivía en win)
- Island: llave sin cerrar del pill (Expected token `}`)

## ✅ Verificación de release

- **0 errores** en el log · isla confirmada oculta en reposo (análisis
  de píxel)
- Tests: settings 182 defaults · welcome · update-check · update-notify ·
  phone-wallpaper · click-away · power-press — **todo verde**
