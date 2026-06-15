<div align="center">

# ⚡ TooFast

### Ship your site in **one command** — and a lot more.

Deploy to Cloudflare Pages, **instant rollback**, real PageSpeed audits, a featherweight GUI,
and a complete developer toolkit. All from your terminal. Zero dependencies beyond `wrangler`.

[![version](https://img.shields.io/badge/version-2.0.0-6d4aff)](https://github.com/nico33t/toofast)
[![shell](https://img.shields.io/badge/bash-5%2B-1f8a55)](#)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

**English** · [Italiano](README.it.md) · [Español](README.es.md) · [Deutsch](README.de.md)

</div>

---

```bash
curl -fsSL https://raw.githubusercontent.com/nico33t/toofast/main/install.sh | bash
```

```bash
too init            # log in to Cloudflare + create a project
too ship client     # build + deploy + QR + open, all in one
too rollback client # ⏪ instantly restore the previous deploy
```

## Why TooFast

`wrangler` deploys. TooFast gives you the **whole workflow** around it: client branches,
build pipelines, quality audits, traffic, a GUI, and the one thing wrangler can't do —
**rollback**.

## ★ Kill feature — Time Machine

Cloudflare has **no CLI rollback** for Pages. TooFast archives every deploy locally,
so you can restore any previous version in seconds.

```bash
too snapshots client          # see the deploy history
too rollback  client          # back to the previous version
too rollback  client 17000000 # roll back to an exact snapshot
```

## Features

| | |
|---|---|
| 🚀 **Deploy** | `too push [dir] [client]` · static folder or auto build (`--build`, detects npm/pnpm/yarn/bun) |
| ⏪ **Time Machine** | local snapshots + true `too rollback` |
| 🔬 **PageSpeed audit** | `too audit` — real score via Google Lighthouse engine (same as pagespeed.web.dev) |
| 🪟 **GUI** | `too gui` — light browser console (shadcn-style), manage clients/projects/settings, served at `nt.local` |
| 📊 **Traffic** | `too analytics inject` to enable Web Analytics, `too stats` to read visits |
| 🧰 **Toolkit** | `too serve`, `too new`, `too build`, `too size`, `too zip`, `too check`, `too qr`, `too clean`, `too doctor`, `too notes` |
| 🛡 **Safe** | exit-code aware, production overwrite confirmation, `--dry-run` |
| 🔄 **Self-updating** | daily check + `too update` (or `NT_AUTO_UPDATE=1`) |

## Commands

```
DEPLOY     too push · too ship · too bp
TIME MACHINE  too rollback · too snapshots
MANAGE     too list · too clients · too projects · too rm · too rmproject · too logs · too open · too copy
QUALITY    too audit · too analytics · too stats
SCAFFOLD   too create · too design · too new · too card (beta)
TOOLKIT    too serve · too build · too size · too zip · too images · too check · too qr · too clean · too doctor · too notes · too gui
SETUP      too init · too config · too update · too version
```

Run `too help` for the full reference. You can also use a single entrypoint: `nt <command>`.

## Scaffold a perfect site

```bash
too create acme            # asks: HTML/CSS/JS or Vite, and whether to start a live-reload dev server
too design add stripe      # pull a brand DESIGN.md from the community library (MIT)
too images .               # convert PNG/JPEG → WebP and rewrite the HTML references
```

`too create` ships a PageSpeed-tuned starter: semantic `index.html`, `DESIGN.md` (9-section
agent spec), `AGENTS.md`, `CLAUDE.md`, `_headers` (CSP + caching), `robots.txt`, `sitemap.xml`,
`site.webmanifest`, `favicon.svg`, `404.html`. AI agents read `DESIGN.md` and ask you to fill
the empty sections before generating UI.

## Claude Code plugin (+ MCP)

Drive TooFast from Claude Code in natural language — deploy, roll back, audit and scaffold.
See [`integrations/claude-code/`](integrations/claude-code/).

## Multiple projects

```bash
too push ./dist client -p other-project    # target any project, one-off
echo 'NT_PROJECT=my-project' > .ntdeploy   # or pin a project per repo
```

## The GUI

```bash
too gui            # opens a light control panel in your browser
too gui dns        # one-time setup to reach it at http://nt.local:7700
```

Light theme, shadcn / next-forge inspired. Manage clients and projects, run audits and checks,
show QR codes, roll back, and configure your **PageSpeed API key** and **Web Analytics tokens**
— all from the browser. It binds to `127.0.0.1` only and runs a strict command whitelist.

## Requirements

- **Node.js** (for `wrangler`, installed automatically if missing)
- Optional: `jq` (richer output), `qrencode` (terminal QR), `python3` (GUI + local server)

## License

MIT © [nico33t](https://github.com/nico33t)
