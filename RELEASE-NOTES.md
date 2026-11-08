# 🫧 2.0.1 — Rebote conectado a la esquina + adiós bloque blanco

## 🐛 Lo que reportaste

- **"Se renderiza algo blanco"**: la cuña de selección era blanca sólida
  (#f5f5f5) — ahora es **tinte del acento al 16 %** con borde de acento
  al 55 %. La selección sigue animada (cuña inclinada + palabra roja)
  pero ya no hay bloque blanco de render.
- **"Que reboten pero conectado a la esquina, se ve raro"**: los paneles
  rebotaban **desplazándose**, así que durante el wobble el slab se
  separaba de la esquina y se veía flotando. Ahora el card está **pegado
  a su esquina SIEMPRE** y el rebote gelatinoso es **scale con origen en
  el borde**: se estira y menea sin despegarse ni un píxel. Verificado
  frame a frame (47/47 columnas tocando el borde durante el rebote).
- La Dynamic Island y el Dock de música usan el mismo tratamiento:
  pegadas al borde derecho, rebote por scale, fade al entrar.
- Fix: `transformOrigin` duplicado en WorkDrawer.

## ✅ Verificación

- **0 errores** en el log
- Tests: settings 183 defaults · welcome · update-check · update-notify ·
  phone-wallpaper · click-away · power-press — **todo verde**
- Frames del rebote analizados: el slab toca la esquina en todo momento
