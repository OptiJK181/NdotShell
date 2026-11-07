## 🖐️ Side drawers estilo Caelestia: tocas el borde y se despliegan

Rediseño completo de los paneles laterales — el fallo que reportaste
(no se ejecutaban bien: un catcher se comía los clics de toda la
pantalla) está arreglado, y ahora se abren **tocando el borde**, como
Caelestia:

- **Hotspot de 8 px** en el borde derecho (Gaming) e izquierdo (Focus).
  Acerca el puntero al borde y el panel **se despliega solo**; aléjalo y
  se recoge (con 450 ms de gracia para no cerrarse en falso).
- **Un toque en el borde también abre** (útil en pantalla táctil).
- `Super + Shift + G` / `Super + Shift + W` **fijan** el panel (pin 📌):
  se queda abierto aunque muevas el puntero; otra vez (o Esc) lo suelta.
- **Cero costo en reposo**: los paneles se desmapean al cerrarse; lo
  único siempre vivo es la franja de 8 px.
- Los clics del escritorio **nunca** se comen: el catcher es
  pass-through (solo hover).

### Panel GAMING (derecha)
Game Mode · Grabadora con timer en vivo · Avisos off · Keep Awake ·
medidores CPU/RAM (muestrean solo abierto).

### Panel FOCUS (izquierda, ofimática)
Pomodoro (Ndot 55, play/pausa/saltar/reset, stats persistentes) ·
Focus Mode · Modo privado del portapapeles · Borrar historial.

## 🔒 `Super + P` — Modo privado (de 1.0.7/1.0.8, intacto)
OSD animado con icono 👁️‍🗨️; secretos nunca grabados; historial en RAM;
auto-wipe al bloquear pantalla.

## 🛠️ Fixes
- Catcher que tragaba clics de toda la pantalla → eliminado
  (pass-through `acceptedButtons: NoButton`)
- Enums no accesibles cross-file → `PomodoroService.idle` expuesto
- Pin 📌 visible en la cabecera del panel fijado
