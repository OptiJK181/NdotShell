<div align="left">

# NdotShell

A **fork of [SekaiPop](https://github.com/Blapples/SekaiPop)** — a Quickshell
desktop for Hyprland, GPL-3.0 — renamed so it can be installed and run
**beside** the original, with its own command, config, state, cache and
plugins.

- Run it with `qs -c ndotshell` (SekaiPop keeps its own `qs -c sekaipop`).
- It starts wearing the **Nothing OS look** (Ndot 55 dot-matrix numerals,
  black / white / red `#d71921`).
- Meant as a **lab**: make widgets, themes and plugins here without touching
  the installed SekaiPop.

<table>
<tr><td>
<b>Name space</b> — what the fork calls things, so the two shells never collide:
</td></tr>
</table>

| thing | SekaiPop | NdotShell |
| --- | --- | --- |
| quickshell config | `~/.config/quickshell/sekaipop` | `~/.config/quickshell/ndotshell` (→ this repo's `ndotshell/`) |
| command | `qs -c sekaipop ...` | `qs -c ndotshell ...` |
| config dir | `~/.config/sekaipop` | `~/.config/ndotshell` |
| state dir | `~/.local/state/sekaipop` | `~/.local/state/ndotshell` |
| cache dir | `~/.cache/sekaipop` | `~/.cache/ndotshell` |
| Hyprland overrides | `~/.config/hypr/sekaipop_overrides.lua` | `~/.config/hypr/ndotshell_overrides.lua` |

Both must **not** run at the same time (they would both own the lockscreen,
notifications and polkit). Use `shell-use <sekaipop|ndotshell>` (in
`~/.local/bin`) to switch.

Docs for a specific feature live in [`docs/`](docs/) (inherited from
upstream red, still accurate). Fork-specific docs: [`docs/NDOT.md`](docs/NDOT.md)
— switching shells, testing a change locally, upstream merging policy, how to
add a widget or plugin.

<b>Attribution and license.</b> Original project by Blapples (see
[`LICENSE`](LICENSE), GPL-3.0). Everything under this name is derived and
contributed to the fork's own purpose; the plugin catalog still points at the
upstream list so both shells share the same plugins.

</div>
