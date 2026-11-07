## ✨ 1.1.0 — Drawers pulidos, 0 errores, listo release

### 🐛 Errores arreglados (auditoría completa del log)

- **16 iconos faltantes** (nombres Material que no existen en el set Solar):
  `local_cafe`, `wb_sunny`, `wb_twilight`, `nightlight`, `branch`, `work`,
  `hourglass_bottom`, `center_focus_strong`, `visibility`, `visibility_off`,
  `delete_sweep`, `fingerprint`, `lock_clock`, `verified`, `system_update`,
  `storefront`, `toolbar`, `campaign`, `gpp_maybe`, `comments_disabled`,
  `notifications` — todos mapeados en `IconMap.js` a archivos Solar reales.
  Fix de un solo punto: también cura los usos upstream de esos nombres.
- **`FocusService.toggle` no era llamable** desde QML (vive dentro del
  IpcHandler): el drawer now toggles vía `SettingsService.toggle`.
- **Hotspot roto**: `containsMouse` referenciado desde el scope de la
  ventana (era la razón por la que "no se ejecutaba bien" el hover).
- **Press-scale roto** en los tiles (id de MouseArea inexistente).

### 🖐️ Interacción Caelestia, ahora correcta

- **Hotspots siempre vivos**: ventanas separadas de 8 px (capa Overlay,
  pass-through total) en el borde derecho (Gaming) e izquierdo (Focus).
  Tocas el borde → el panel se despliega; te alejas → se recoge (450 ms
  de gracia). Un toque también abre (táctil).
- La franja **se ilumina con una línea de acento de 2 px** cuando el
  puntero toca el borde: el borde dice "abro algo".
- Los paneles se desmapean al cerrarse (**costo idle cero**) — y el bug
  del huevo y la gallina (hotspot dentro de la ventana del drawer) es
  historia.

### 🎨 Apariencia (lenguaje Nothing)

- **Línea de acento de 2 px** del canal a lo largo del borde de pantalla
  de cada drawer abierto
- Cabecera: título Ndot 55 + kicker con tracking ("MODO RENDIMIENTO" /
  "OFIMÁTICA"), chip **FIJADO** (adiós emoji 📌), hairline bajo la
  cabecera
- Tiles rediseñados: **placas de icono de 40 px** con tinte de acento al
  activarse, **press-scale 0.97**, radio mayor, ritmo más apretado

## ⌨️ Atajos

| Atajo | Acción |
|---|---|
| tocar borde derecho | Panel Gaming |
| tocar borde izquierdo | Panel Focus |
| `Super + Shift + G` / `W` | Fijar/soltar panel |
| `Super + P` | Modo privado + OSD |
| `Esc` | Cerrar panel |

**0 errores en el log. Tests: settings (178), welcome, update-check,
update-notify, phone-wallpaper — todos en verde.**
