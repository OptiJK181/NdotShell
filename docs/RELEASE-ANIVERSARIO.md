# 🎂 3.0.0 — Aniversario (13 de noviembre)

> Borrador de notas para la release del 13 de noviembre. Publicar con:
> `git tag v3.0.0 && git push fork v3.0.0 && gh release create v3.0.0 --title "3.0.0 — Aniversario: dos bolitas con sentimientos" --notes-file docs/RELEASE-ANIVERSARIO.md`

## 👀 Dos bolitas con sentimientos

La carita quedó simple y linda: **dos bolitas** redondas que te siguen, parpadean, y se cambian de cara según la respuesta — **feliz** `^ ^` con brinco gelatinoso, **enojado** (un párpado corta cada bola), **triste** (caídas, con lagrimita), **dormido** (líneas cerradas con zZ flotando) y **sorprendido** cuando la tocas. Un error la pone enojada.

Y cuesta menos que nunca: todos sus relojes se detienen cuando Focus Mode esconde la card.

## ⚡ La IA te ayuda con la compu

Pídele cosas: *"ábreme chrome y vesktop para trabajar"*. La respuesta llega con un bloque de comando y una tecla **▶ Ejecutar** — en el chat y en la card del gatito. **Nada corre hasta que tú aprietes la tecla**, y todo lo ejecutado queda en `~/.local/state/ndotshell/ai-runs.log`.

```
▶ Ejecutar su propuesta
google-chrome-stable & vesktop &
```

- **Modo agente** (Ajustes → IA, apagado por defecto): con opencode, el CLI aprueba sus propios permisos (`--auto`) y el gatito puede actuar de verdad.
- Funciona con **cualquier proveedor** (la convención viaja siempre con tu prompt).

## 🎵 El dock que canta

El dock de música ya no está solo:

- **Barra de progreso** con el punto rojo, los dos tiempos y **seek** (un toque donde quieras ir).
- **La letra en vivo**: la línea que suena ahora, en la fuente display, con la que viene atenuada debajo.

## 🧩 Paneles con compañía

Gaming y Work cierran con un pie de **"ahora suena"**: puntito que respira, track y artista, play/pausa — y un toque abre el dock completo.

---

**Full changelog**: https://github.com/OptiJK181/NdotShell/compare/v2.8.0...v3.0.0
