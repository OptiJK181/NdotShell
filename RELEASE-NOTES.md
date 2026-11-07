# NdotShell 1.0.3

## ✨ Nuevas Features

### 📋 Clipboard History
- Historial del portapapeles (texto e imágenes, hasta 50 items)
- Anclar (pin) items importantes
- Búsqueda en tiempo real
- Click para copiar al portapapeles
- Integración en Settings → General → Clipboard history

### 🎥 Screen Recorder
- Grabar pantalla completa, ventana seleccionada o región
- Con/sin audio del sistema
- Tile en Quick Panel con indicador visual de grabación
- Notificación al terminar con archivo guardado
- Settings → Quick → Grabadora de pantalla

### ⏱️ Pomodoro Timer
- Ciclos 25/5 min configurables
- Descanso largo cada N ciclos
- Estadísticas persistentes (ciclos hoy, tiempo total)
- Auto-inicio de descansos/trabajo opcional
- Notificaciones nativas
- Widget en Edit Desktop + Settings → General → Pomodoro

### 🌅 Dynamic Wallpaper (Wallpaper por hora)
- Cambio automático: mañana (6-10), día (10-18), tarde (18-22), noche (22-6)
- Transición suave configurable (1-120 min)
- Modo manual: el usuario elige una imagen
- Settings → Desktop → Wallpaper dinámico

---

## 🔧 Mejoras al Sistema de Actualizaciones

- **Fix crítico**: `update-check.sh` ahora prioriza `.source` sobre detección git
  - Fix para instalaciones symlinkadas (managed install)
  - Fix para "nothing to compare with" / "no tiene repo"
- Prioridad de remoto: `$NDOTSHELL_REPO` → `.source` → `~/.config/ndotshell/update-repo` → remote `fork` → `origin` (solo si no es SekaiPop)
- Canales `stable` (main) / `dev` (dev) funcionando en Settings → About
- `apply` hace swap atómico + actualiza `VERSION` y `.source` automáticamente

---

## 🐛 Bugs Corregidos

- Settings → About/Update: botón "Update now" funcional
- Prioridad `.source` sobre detección git (fix para symlinks)
- Canal `dev` creado en GitHub
- Tags y releases automatizados

---

## 📦 Instalación / Actualización

```bash
# Instalar
bash <(curl -fsSL https://raw.githubusercontent.com/OptiJK181/NdotShell/main/get.sh) --yes

# Actualizar (desde la shell)
# Settings → About / Update → Update now
# O CLI:
update-check.sh apply
```

---

**Commit**: `5da1fe3` | **Canal**: `dev` / `stable` (main)
