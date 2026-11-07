# NDOT.md — the fork's own manual

Everything that is *different* about running this fork, on top of the docs
upstream already ships (in `docs/`).

## Switching between SekaiPop and NdotShell

This fork lives at `~/dev/ndotshell`, linked into place:

```
~/.config/quickshell/ndotshell -> ~/dev/ndotshell/ndotshell
```

Only one of the two shells runs at a time. Helpers (all in `~/.local/bin`):

| helper | what it does |
| --- | --- |
| `shell-use <name>` | switch: stops the running shell, starts `<name>` (`sekaipop` or `ndotshell`), reloads Hyprland |
| `qs-run [qs args…]` | launches the shell chosen with `shell-use` |
| `qs-autostart` | what Hyprland runs at login: waits for Wayland, starts the chosen shell and retries until it is registered |
| `qs-ipc ipc call …` | sends IPC to whichever shell is running (Hyprland keybinds use this) |
| `qs-restart` | restarts the running shell (or, if none, the chosen one) — same as the keybind |
| `ndotshell` | `shell-use ndotshell` |

The current choice is stored in `~/.local/state/shell-current`.

Hyprland integration is shared, one config, two names:

- `~/.config/hypr/hyprland/variables.lua`: `QS` / `QS_IPC` point at the two
  helpers (set in `custom/variables.lua`), so every keybind lands in the shell
  that is actually running. `QS` is `qs-autostart` (the login wrapper);
  `QS_IPC` is `qs-ipc`.
- `~/.config/hypr/hyprland/rules.lua`: layer rules match
  `^(sekaipop|ndotshell)-`, so blur / no-anim rules work for whichever shell
  is up.
- `~/.config/hypr/hyprland.lua` loads both override files:
  `sekaipop_overrides` and `ndotshell_overrides`. Each shell writes only its
  own file (Settings > Hyprland). Keep in mind: if both files rebind the same
  keys, the one loaded last (`ndotshell_overrides`) wins.
- Idle: `shell-use` also points `~/.config/hypr/hypridle.conf`'s
  `source =` line at the chosen shell's `idle.conf` and restarts hypridle,
  so only one set of idle timers is live. (Each shell creates that line the
  first time from its own Settings, and keeps its own thereafter.)

## Starting NdotShell

```
qs -c ndotshell -d          # detached (what shell-use does)
```

At login Hyprland runs `qs-autostart` (set as `QS` in
`~/.config/hypr/custom/variables.lua`). It waits for the Wayland socket,
starts whichever shell `shell-use` selected, verifies that Quickshell
registered it, and retries up to three times. That covers both a
`hyprland.start` that fires early and a config error that would otherwise
leave the session with no bar, dock or lock screen.

If the desktop ever comes up without the shell:

```
qs-autostart                      # run it by hand, same path as login
tail -n 40 ~/.cache/ndotshell/autostart.log
```

The log is truncated at 256 KB automatically.

First useful checks:

```
qs -c ndotshell ipc call theme modeGet
```

## Testing a change before it "ships"

The repo is the live code: `qs -c ndotshell` runs what you edit (Quickshell
reloads the config when you change it, or use `qs-restart`). Logs land in
`/run/user/1000/quickshell/by-*/log.qslog` — grep them for `error` after a
change.

Tests (node / shell, no Quickshell needed) live under `ndotshell/tests/*-test`
with a run-tests.sh each; e.g.
`node ndotshell/tests/palette-test/palette_unit.js`.

## Making a widget

Two entry points, both local to this fork:

1. **A plugin** (external, like for SekaiPop): folder with a `plugin.json`,
   install it from Settings > About/Update > Plugins, or link a folder. See
   `docs/PLUGIN-INSTALL.md` and `examples/plugins/`. The catalog is the
   upstream `plugins.json`, and anything you put in
   `~/.config/ndotshell/plugins/` is yours alone.
2. **A shell widget** (in the fork's code): desktop widgets live in
   `modules/sekai/desktopWidgets/` and register in `services/PresetWidgets.qml`.
   Start from the smallest one (`TodoWidget.qml` is more typical than you'd
   think) and read `docs/` for the services it talks to.

## The Now Playing widget

`modules/sekai/desktopWidgets/NowPlayingWidget.qml` is a real desktop card
(not a bar pill): it reads the current track live from MPRIS
(`services/MediaSource.qml`), with cover art, title, artist, album, a seek
lane (click / drag / wheel) and previous / play / next. Its state lives in
`services/NowPlayingService.qml` and is saved by
`scripts/state/nowplaying-state.sh` to
`${XDG_STATE_HOME:-~/.local/state}/ndotshell/nowplaying.json`.

It is off until you add it (Edit Desktop's shelf, Settings > Desktop, or the
IPC). Two sizes: `full` (cover beside the text) and `2x2` (tall and
centred).

```
qs -c ndotshell ipc call nowplaying toggle
qs -c ndotshell ipc call nowplaying size 2x2      # or: full
qs -c ndotshell ipc call nowplaying toggleSize
qs -c ndotshell ipc call nowplaying resetPosition
```

Drag it on an unlocked desktop (or with Edit Desktop's shield), and resize it
with the size key that appears when it is selected while editing.

## The Ndot channels

NdotShell has one permanent design — Nothing OS: black slabs, a 1 px grey
hairline, white ink, Ndot 55 on the big numerals, no hard shadows, and a
single accent — and six **channels** that only swap that accent. The design
never changes; the channel is chosen in the theme picker (or by IPC) and is
remembered in `~/.local/state/ndotshell/theme`.

| channel | accent | file id |
| --- | --- | --- |
| Ndot Red | `#d71921`, the signature red (default) | `nothing` |
| Ndot Mono | white / silver, no hue at all | `ndotmono` |
| Ndot Amber | warm amber | `ndotamber` |
| Ndot Lime | acid lime | `ndotlime` |
| Ndot Blue | cobalt | `ndotblue` |
| Ndot Violet | violet | `ndotviolet` |

The channel list lives in `services/ThemeService.qml` (`baseGroups`). Every
entry sets `dot: true` (Ndot 55 numerals) and `mono: true` (every derived
colour stays neutral, so the accent is the only hue). The Project Sekai unit
themes are gone from this fork; `extraGroups` is empty, so Matugen and the
Palette tool still appear after the channels.

```
qs -c ndotshell ipc call theme set ndotblue
qs -c ndotshell ipc call theme get
```

The design itself is in `modules/common/ThemeSet.qml`: `nothing` is true when
the active palette says `dot: true`, and it remaps `surface`, `line`,
`ringWhite`, `chipFill`, `chipInk`, `borderWidth` (1), `shadowOffset` (0) and
`outerRingWidth` (1) onto the `nb*` colours (`#0b0b0b` surface, `#2b2b2b`
hairline, `#f5f5f5` ink, `#8f8f8f` sub-ink). Because those are the same
properties the Sekai skin already used, every popup, card and pill follows
without being touched one by one.

## The Nothing bar and dock

Both use the **Capsule** layout in the Nothing skin:

- bar: 36 px black slab, 1 px `#2b2b2b` rim, no shadow. Workspaces are flat
  hairline badges with Ndot numbers; the active workspace turns red and the
  capsule dots stay grey except the active red one.
- chips: black fill, white ink, Ndot 55 on the clock, date, weather, battery
  and resource percentages, keyboard layout, notification count and the media
  title. Media artist uses the sub-ink grey. There is one red accent per
  surface, never two.
- dock: round black keys, 1 px rim, monochrome app icons (saturation off), the
  focused dot red and a running app's dot white.

Bar and dock style are saved separately from the channel:

```
qs -c ndotshell ipc call barstyle set capsule
cat ~/.local/state/ndotshell/bar-style
```

## Updating: stable vs dev channel

NdotShell updates from **its own repo** (read from, in order: `$NDOTSHELL_REPO`,
`repo=` in the `.source` file beside `shell.qml`, `~/.config/ndotshell/update-repo`,
the git remote named `fork`, then `origin` only when it is not SekaiPop). It
never falls back to SekaiPop's repo.

There are two channels, stored in `~/.config/ndotshell/update-channel`:

| channel | branch | what it tracks |
| --- | --- | --- |
| `stable` (default) | `main` | the fork's `main` branch — released, tested |
| `dev` | `dev` | the fork's `dev` branch — what lands between releases |

The channel is chosen in **Settings → About / Update → Update channel**, or:

```
qs -c ndotshell ipc call settings page about
# then flip "Update channel" in the page, or:
update-check.sh channel dev          # store and print the channel
update-check.sh channel              # print the current channel
```

`update-check.sh info` prints `channel=` alongside `version=`, `git=`, `managed=`,
`branch=`, `commit=` and `remote=`. `check` compares the installed mark against the
channel branch's newest commit (git fetch for a checkout, `git ls-remote` for an
installed copy). `log` lists the commits an update would bring. `apply` downloads
the channel branch and swaps the folder in (`git pull --ff-only` for a checkout,
a shallow clone + swap for an installed copy), then restarts the shell.

Bringing upstream SekaiPop work in is still manual, on purpose: the rename must
be re-applied so upstream code never clobbers it.

```
git fetch origin
git merge origin/main          # resolve as usual
python3 maintain/reapply-rename.py   # re-apply the rename; idempotent
git add -A && git commit
qs-restart
```

`maintain/reapply-rename.py` moves every file whose path still says sekaipop
and rewrites the tokens (`SEKAIPOP`/`SekaiPop`/`Sekaipop`/`sekaipop` → the
ndotshell family), protecting the widget name `SekaiPopup`. Run it after every
merge, and expect the leftover check to be clean.

## Versioning and name notes

- `ndotshell/VERSION` still says `1.0.0` matching upstream at fork time.
- The Project Sekai unit themes are replaced by the six Ndot channels (see
  above); the code still lives in `modules/sekai/` and `SekaiPopup` keeps its
  name, because that is the upstream design language, not the shell's brand.
- The Nothing skin is baked into this fork rather than kept as patches in
  `~/.local/share/sekaipop-nothing/`: `ThemeSet.qml` (`nb*` colours,
  `fontDisplay`, hairline widths), `ThemeService.qml` (the channel groups),
  the bar/dock restyle, the big clock numerals and the lockscreen clock.
