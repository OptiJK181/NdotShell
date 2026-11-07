## 🏝️ 1.2.0 — Dynamic Island + menús estilo Sekai + Barras de tareas

### 🐛 El error de tu captura, arreglado

El **"Listo" montaba sobre el borde** de la tarjeta Pomodoro: tarjeta
agrandada (186), contenido centrado con márgenes propios y el borde
acento ahora solo mientras **corre** (no en idle).

### 🏝️ Dynamic Island (Apple-style, vestido Nothing)

Píldora top-center bajo la barra:
- **Compacta**: reloj Ndot 55 + punto rojo (grabando) + punto cian
  (Pomodoro corriendo)
- **Hover** → se abre con **OutBack spring** en tres mini-paneles:
  - **RELOJ** — numerale grande + fecha
  - **MÚSICA** — título/artista + prev ▷ play ⏭ next
  - **POMODORO / REC** — timer (o timer de grabación en rojo) + play · videocam
- Esc o alejar el puntero cierra · toggles en Ajustes

### ✨ Selección estilo Sekai (tu referencia)

`DrawerMenuItem`: texto grande itálico en Ndot 55; al hover/selección
**una cuña blanca inclinada se desliza** por detrás y la palabra **se
levanta y se pinta del acento del canal** — exactamente la animación de
la captura (SHUTDOWN rojo sobre cuña blanca), en colores Nothing.

**Gaming**: GAME MODE · GRABAR PANTALLA (con timer vivo en la palabra) ·
GRABAR VENTANA · GRABAR REGIÓN · CAPTURA · AVISOS · KEEP AWAKE + SISTEMA.

**Focus**: POMODORO (tarjeta) · FOCUS MODE · MODO PRIVADO · BORRAR
HISTORIAL · NOTAS · TO-DO · CALENDARIO.

### ⚙️ Nuevo apartado "Barras de tareas" (Ajustes → Escritorio)

Toggles para: Panel Gaming, Panel Focus, **abrir tocando el borde**
(hotspots) y **Dynamic Island** — todo persistente (`side.*`).

## ✅ Verificación de release

- **0 errores** en el log (ReferenceError/TypeError/non-existent
  property/Failed to load/Cannot open — todo limpio)
- Tests: settings (**182 defaults**), welcome, update-check, update-notify — verdes
- Capturas verificadas: isla compacta renderiza (píldora + reloj Ndot),
  Focus drawer con cuñas de selección, hairline de acento

## ⌨️ Chuleta

| Atajo | Acción |
|---|---|
| tocar borde derecho / izquierdo | Gaming / Focus |
| `Super + Shift + G` / `W` | Fijar panel |
| `Super + P` | Modo privado + OSD |
| hover píldora superior | Dynamic Island expandida |
