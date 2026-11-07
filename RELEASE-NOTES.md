# NdotShell 1.0.6

## ✨ Nuevas Features (desde 1.0.0)

### 📋 Clipboard History
- Historial del portapapeles (texto e imágenes, hasta 50 items)
- Anclar (pin) items importantes, búsqueda en tiempo real
- Click para copiar al portapapeles
- Settings → General → Clipboard history

### 🎥 Screen Recorder
- Grabar pantalla completa, ventana o región, con/sin audio
- Tile en Quick Panel con indicador visual de grabación
- Notificación al terminar con archivo guardado
- Settings → Quick → Grabadora de pantalla

### ⏱️ Pomodoro Timer
- Ciclos 25/5 min configurables, descanso largo cada N ciclos
- Estadísticas persistentes (ciclos hoy, tiempo total)
- Notificaciones nativas
- Widget en Edit Desktop + Settings → General → Pomodoro

### 🌅 Dynamic Wallpaper (por hora)
- Cambio automático: mañana (6-10), día (10-18), tarde (18-22), noche (22-6)
- Transición suave configurable (1-120 min), modo manual
- Settings → Desktop → Wallpaper dinámico

## 🔧 Sistema de Actualizaciones

- **Fix crítico**: `update-check.sh` prioriza `.source` sobre detección git
  - Fix para instalaciones symlinkadas (managed install)
  - Fix para "nothing to compare with" / "no repo"
- **Fix crítico**: `herep` usa path lógico (conserva symlinks) en managed install
- Canales `stable` (main) / `dev` (dev) funcionando en Settings → About
- `apply` hace swap atómico + actualiza `.source` automáticamente
- Detecta commits nuevos correctamente (`behind` → `apply` → `current`)

## 🐛 Bugs Corregidos

- TypeError: Property 'replace' of QUrl is not a function (services)
- ReferenceError: FileSystem is not defined (services)
- Update check detectaba mal el repo (usaba SekaiPop en vez del fork)
- Canal `dev` creado en GitHub para updates
- Settings → About/Update: botón "Update now" funcional

## 📦 Instalación / Actualización

```bash
# Instalar
bash <(curl -fsSL https://raw.githubusercontent.com/OptiJK181/NdotShell/main/get.sh) --yes

# Actualizar (desde la shell)
# Settings → About / Update → Update now
# O CLI:
update-check.sh apply
```
