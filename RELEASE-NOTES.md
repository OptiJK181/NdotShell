# 🫧 2.0.2 — La hitbox blanca era el fondo del hotspot + zonas funcionales

## 🐛 Lo que viste: "es la hitbox del botón brooo"

Exacto. El `PanelWindow` de los hotspots **no tenía `color: "transparent"`** —
Quickshell pinta el fondo de la ventana **BLANCO por defecto**, y la hitbox
se veía como franja blanca en las esquinas donde tocas. Ahora es
transparente: **0 blancos** en las 4 zonas (verificado por píxel).

## 🐛 Y los botones que no respondían

Los hotspots de **isla** (mid) y **música** (bottom) eran ventanas de
**altura 0** — sin input, el doble toque nunca podía funcionar. Además los
hotspots no tenían máscara, así que sus ventanas completas podían comerse
clics del borde.

Ahora: **windows de borde completo con `mask: Region { item: ma }`** — la
entrada vive SOLO en la franja de 10 px de cada zona; todo lo demás (barra,
ventanas, widgets) recibe sus clics normal.

## 🖐️ Zonas de doble toque (todas funcionales)

| Zona | Abre |
|---|---|
| esquina superior derecha ×2 | Panel GAMING |
| esquina superior izquierda ×2 | Panel FOCUS |
| lateral derecho, al medio ×2 | Isla (agujero negro) |
| esquina inferior derecha ×2 | **Dock de música** 🎶 |

## ✅ Verificación

- 0 blancos en las 4 zonas (píxel)
- 0 errores en el log
- Capas correctas: 4 hotspots 10×1080 con máscara de zona, isla oculta
  hasta keybind, dock oculto hasta doble toque
- Tests: settings 183 · welcome · update-check · update-notify ·
  phone-wallpaper · click-away · power-press — verdes
