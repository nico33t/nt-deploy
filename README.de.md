<div align="center">

# ⚡ TooFast

### Bring deine Seite online — mit **einem Befehl**, und vielem mehr.

Deploy auf Cloudflare Pages, **sofortiges Rollback**, echte PageSpeed-Audits, eine leichte GUI
und ein komplettes Entwickler-Toolkit. Alles im Terminal. Keine Abhängigkeiten außer `wrangler`.

[![version](https://img.shields.io/badge/version-2.0.0-6d4aff)](https://github.com/nico33t/toofast)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

[English](README.md) · [Italiano](README.it.md) · [Español](README.es.md) · **Deutsch**

</div>

---

```bash
curl -fsSL https://raw.githubusercontent.com/nico33t/toofast/main/install.sh | bash
```

```bash
too init             # bei Cloudflare anmelden + Projekt anlegen
too ship kunde       # Build + Deploy + QR + öffnen, alles in einem
too rollback kunde   # ⏪ sofort den vorherigen Deploy wiederherstellen
```

## Warum TooFast

`wrangler` deployt. TooFast gibt dir den ganzen **Workflow** drumherum: Branches pro Kunde,
Builds, Qualitäts-Audits, Traffic, eine GUI — und das Eine, was wrangler allein nicht kann:
**Rollback**.

## ★ Killer-Feature — Time Machine

Cloudflare bietet kein CLI-Rollback für Pages. TooFast archiviert jeden Deploy lokal,
so stellst du jede Version in Sekunden wieder her.

```bash
too snapshots kunde          # Deploy-Verlauf
too rollback  kunde          # zurück zum vorherigen
too rollback  kunde 17000000 # zu einem genauen Snapshot
```

## Funktionen

| | |
|---|---|
| 🚀 **Deploy** | `too push [dir] [kunde]` · statischer Ordner oder automatischer Build (`--build`) |
| ⏪ **Time Machine** | lokale Snapshots + echtes `too rollback` |
| 🔬 **PageSpeed-Audit** | `too audit` — echter Score (Google-Lighthouse-Engine) |
| 🪟 **GUI** | `too gui` — leichte Browser-Konsole (shadcn-Stil), unter `nt.local` |
| 📊 **Traffic** | `too analytics inject` für Web Analytics, `too stats` für Besuche |
| 🧰 **Toolkit** | `too serve`, `too create`, `too design`, `too images`, `too zip`, `too check`, `too qr`, `too clean`, `too doctor`, `too notes` |
| 🛡 **Sicher** | Exit-Code-bewusst, Bestätigung in Produktion, `--dry-run` |

## Eine perfekte Seite erzeugen

```bash
too create acme       # fragt: HTML/CSS/JS oder Vite, und ob ein Dev-Server mit Live-Reload starten soll
too design add stripe # holt eine Marken-DESIGN.md aus der Community-Bibliothek (MIT)
too images .          # konvertiert PNG/JPEG → WebP und schreibt die HTML-Referenzen um
```

`too create` liefert einen PageSpeed-optimierten Starter: semantisches `index.html`, `DESIGN.md`
(9-Abschnitt-Spec für KI-Agenten), `AGENTS.md`, `CLAUDE.md`, `_headers` (CSP + Caching),
`robots.txt`, `sitemap.xml`, `site.webmanifest`, `favicon.svg`, `404.html`.

## Claude-Code-Plugin (+ MCP)

Steuere TooFast aus Claude Code in natürlicher Sprache. Siehe [`integrations/claude-code/`](integrations/claude-code/).

## Voraussetzungen

- **Node.js** (für `wrangler`, wird bei Bedarf automatisch installiert)
- Optional: `jq`, `qrencode`, `python3` (GUI + lokaler Server), `cwebp` (Bildkonvertierung)

## Lizenz

MIT © [nico33t](https://github.com/nico33t)
