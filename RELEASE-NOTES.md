# NdotShell 1.0.0

Quickshell desktop para Hyprland, fork renombrado de SekaiPop. Diseño Nothing
permanente: bar/dock cápsula, seis canales de acento (Ndot Red por defecto,
Mono, Amber, Lime, Blue, Violet), teléfono holograma 2.5D, welcome tour
mejorado y canales de actualización propios (estable = main, dev = dev).

## Instalación automática

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/[TU-USUARIO]/NdotShell/main/get.sh)
```

O clona y ejecuta `./install.sh`.

## ¿Qué cambia respecto a SekaiPop?

- Renombrado completo: `qs -c ndotshell`, `~/.config/ndotshell`,
  `~/.cache/ndotshell`, `~/.local/state/ndotshell`, `qs-autostart`.
- Nothing skin en bar y dock (estilo cápsula, 1 px rim, sin sombras).
- Teléfono con render holograma 2.5D: pantalla nítida y opaca, extrusión con
  filamento de acento, pared lateral translúcida, alambre trasero y halo.
- Welcome tour: letra Ndot/Shell, marca de punto, paleta papel/tinta, rejilla
  de fondo, barrido de scanlines y glitch del héroe al cambiar de diapositiva.
- `update-check.sh channel [stable|dev]`; `info`, `check`, `log` y `apply`
  leen del repo del fork (nunca de SekaiPop).
- Autostart vía `qs-autostart` tras reinicio.
- GPL-3.0, versión 1.0.0.
