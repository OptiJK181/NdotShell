## 🔒 Privacidad (lo grande de esta versión)

**Clipboard history rediseñado para ser privado de fábrica:**

- **Filtro de secretos**: contraseñas, api keys, tokens (`sk-`, `ghp-`, `xox`), Bearer auth, JWTs, llaves privadas, números de tarjeta y hex largo **nunca se graban** en el historial. Suite de tests: 8/8.
- **Modo privado**: `qs -c ndotshell ipc call clipboard private on` pausa la grabación por completo (ideal para sesiones sensibles).
- **El historial vive en RAM**: nada del portapapeles va a disco salvo lo que **fijes tú** (pin). Un disco robado o una captura de `~/.config` no revela qué copiaste.
- **Auto-wipe al bloquear pantalla**: el historial se borra solo cuando se bloquea la sesión.
- **Cero red**: auditoría hecha — ningún servicio nuevo hace llamadas de red ni telemetría; el watcher del portapapeles es polling local.

## ✅ Persistencia real

- **Pomodoro**: estadísticas (ciclos de hoy, tiempo trabajado, all-time) persisten entre reinicios vía `service-state.sh` (Process + shell I/O, sin FileSystem). Los contadores diarios se resetean al cambiar la fecha.
- **Pinned del clipboard**: sobreviven reinicios.

## 🛠️ Otros fixes

- TypeError `QUrl.replace()` en services nuevos (ScreenRecorder/Pomodoro/DynamicWallpaper)
- Singletons instanciados en `shell.qml` desde el primer frame → sus IPC y timers existen siempre
- Update system verificado end-to-end: `behind` → `apply` → `current`

## 📦

```bash
# Actualizar
# Settings → About / Update → Update now
# o:
update-check.sh apply
```
