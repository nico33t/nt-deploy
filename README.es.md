<div align="center">

# ⚡ TooFast

### Publica tu sitio en **un comando** — y mucho más.

Despliega en Cloudflare Pages, **rollback instantáneo**, auditorías PageSpeed reales, una GUI
ligera y un toolkit completo para desarrolladores. Todo desde la terminal. Sin dependencias
salvo `wrangler`.

[![version](https://img.shields.io/badge/version-2.0.0-6d4aff)](https://github.com/nico33t/toofast)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

[English](README.md) · [Italiano](README.it.md) · **Español** · [Deutsch](README.de.md)

</div>

---

```bash
curl -fsSL https://raw.githubusercontent.com/nico33t/toofast/main/install.sh | bash
```

```bash
too init             # inicia sesión en Cloudflare + crea el proyecto
too ship cliente     # build + deploy + QR + abrir, todo en uno
too rollback cliente # ⏪ restaura al instante el despliegue anterior
```

## Por qué TooFast

`wrangler` despliega. TooFast te da todo el **flujo de trabajo** alrededor: ramas por cliente,
builds, auditorías de calidad, tráfico, una GUI, y lo único que wrangler no puede hacer:
el **rollback**.

## ★ Función estrella — Time Machine

Cloudflare no ofrece rollback por CLI para Pages. TooFast archiva cada despliegue en local,
así puedes restaurar cualquier versión en segundos.

```bash
too snapshots cliente          # historial de despliegues
too rollback  cliente          # vuelve al anterior
too rollback  cliente 17000000 # a un snapshot exacto
```

## Funciones

| | |
|---|---|
| 🚀 **Deploy** | `too push [dir] [cliente]` · carpeta estática o build automático (`--build`) |
| ⏪ **Time Machine** | snapshots locales + `too rollback` real |
| 🔬 **Auditoría PageSpeed** | `too audit` — puntuación real (motor Google Lighthouse) |
| 🪟 **GUI** | `too gui` — consola ligera en el navegador (estilo shadcn), en `nt.local` |
| 📊 **Tráfico** | `too analytics inject` para activar Web Analytics, `too stats` para las visitas |
| 🧰 **Toolkit** | `too serve`, `too create`, `too design`, `too images`, `too zip`, `too check`, `too qr`, `too clean`, `too doctor`, `too notes` |
| 🛡 **Seguro** | control de exit-code, confirmación en producción, `--dry-run` |

## Crea un sitio perfecto

```bash
too create acme       # pregunta: HTML/CSS/JS o Vite, y si arrancar un dev server con recarga en vivo
too design add stripe # descarga un DESIGN.md de marca de la biblioteca de la comunidad (MIT)
too images .          # convierte PNG/JPEG → WebP y reescribe las referencias del HTML
```

`too create` genera un starter optimizado para PageSpeed: `index.html` semántico, `DESIGN.md`
(spec de 9 secciones para agentes de IA), `AGENTS.md`, `CLAUDE.md`, `_headers` (CSP + caché),
`robots.txt`, `sitemap.xml`, `site.webmanifest`, `favicon.svg`, `404.html`.

## Plugin de Claude Code (+ MCP)

Usa TooFast desde Claude Code en lenguaje natural. Ver [`integrations/claude-code/`](integrations/claude-code/).

## Requisitos

- **Node.js** (para `wrangler`, se instala automáticamente si falta)
- Opcionales: `jq`, `qrencode`, `python3` (GUI + servidor local), `cwebp` (conversión de imágenes)

## Licencia

MIT © [nico33t](https://github.com/nico33t)
