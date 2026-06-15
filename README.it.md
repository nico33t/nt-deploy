<div align="center">

# ⚡ TooFast

### Pubblica il tuo sito in **un comando** — e molto di più.

Deploy su Cloudflare Pages, **rollback istantaneo**, audit PageSpeed reali, una GUI leggera
e un toolkit completo per sviluppatori. Tutto dal terminale. Zero dipendenze oltre a `wrangler`.

[![version](https://img.shields.io/badge/version-2.0.0-6d4aff)](https://github.com/nico33t/toofast)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

[English](README.md) · **Italiano** · [Español](README.es.md) · [Deutsch](README.de.md)

</div>

---

```bash
curl -fsSL https://raw.githubusercontent.com/nico33t/toofast/main/install.sh | bash
```

```bash
too init            # login Cloudflare + crea il progetto
too ship cliente    # build + deploy + QR + apri, tutto in uno
too rollback cliente # ⏪ ripristina all'istante il deploy precedente
```

## Perché TooFast

`wrangler` fa il deploy. TooFast ti dà tutto il **flusso di lavoro** intorno: branch per
cliente, build, audit di qualità, traffico, una GUI, e l'unica cosa che wrangler non sa fare:
il **rollback**.

## ★ Kill feature — Time Machine

Cloudflare non offre rollback da CLI per Pages. TooFast archivia ogni deploy in locale,
così puoi ripristinare qualunque versione in pochi secondi.

```bash
too snapshots cliente          # storico dei deploy
too rollback  cliente          # torna al precedente
too rollback  cliente 17000000 # a uno snapshot esatto
```

## Funzioni

| | |
|---|---|
| 🚀 **Deploy** | `too push [dir] [cliente]` · cartella statica o build automatica (`--build`) |
| ⏪ **Time Machine** | snapshot locali + `too rollback` vero |
| 🔬 **Audit PageSpeed** | `too audit` — punteggio reale (motore Google Lighthouse) |
| 🪟 **GUI** | `too gui` — console leggera nel browser (stile shadcn), su `nt.local` |
| 📊 **Traffico** | `too analytics inject` per attivare Web Analytics, `too stats` per le visite |
| 🧰 **Toolkit** | `too serve`, `too create`, `too design`, `too images`, `too zip`, `too check`, `too qr`, `too clean`, `too doctor`, `too notes` |
| 🛡 **Sicuro** | controllo exit-code, conferma in produzione, `--dry-run` |

## Scaffold di un sito perfetto

```bash
too create acme       # chiede: HTML/CSS/JS o Vite, e se avviare un dev server con live reload
too design add stripe # scarica un DESIGN.md di brand dalla libreria community (MIT)
too images .          # converte PNG/JPEG → WebP e riscrive i riferimenti nell'HTML
```

`too create` genera uno starter ottimizzato per PageSpeed: `index.html` semantico, `DESIGN.md`
(spec a 9 sezioni per agenti AI), `AGENTS.md`, `CLAUDE.md`, `_headers` (CSP + cache),
`robots.txt`, `sitemap.xml`, `site.webmanifest`, `favicon.svg`, `404.html`.

## Plugin Claude Code (+ MCP)

Usa TooFast da Claude Code in linguaggio naturale. Vedi [`integrations/claude-code/`](integrations/claude-code/).

## Requisiti

- **Node.js** (per `wrangler`, installato in automatico se manca)
- Opzionali: `jq`, `qrencode`, `python3` (GUI + server locale), `cwebp` (conversione immagini)

## Licenza

MIT © [nico33t](https://github.com/nico33t)
