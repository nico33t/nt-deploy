# 🔪 nt-deploy

**🇮🇹 Italiano** · [🇬🇧 English](README.en.md)

Coltellino svizzero da terminale per pubblicare anteprime statiche su **Cloudflare Pages** con un comando. Ogni cliente prende il suo sottodominio dinamico, senza configurare hosting, DNS, o repo Git.

```bash
nt-push ./dist mario-rossi
# ✅ Online: https://mario-rossi.studio-acme.pages.dev
```

> Il dominio base (`studio-acme.pages.dev` qui sopra) lo scegli tu al primo `nt-init`. Ogni utente ha il suo: chi installa nt-deploy decide come si chiama il proprio "spazio anteprime" (es. `nicolatomassini.pages.dev`, `studiorossi.pages.dev`, `progetti.pages.dev`...).

## ✨ Cosa fa

- **Deploy istantaneo** di qualsiasi cartella statica (build di React, Vue, Astro, Next export, HTML puro…)
- **Sottodomini dinamici per cliente** → ogni cliente ha il suo URL condivisibile
- **Sostituzione facile** → rilanci il comando, l'anteprima si aggiorna sullo stesso URL
- **Comandi rapidi** → `nt-copy mario-rossi` per copiare il link da mandare via WhatsApp
- **Auto-aggiornamento** → ti avvisa quando esce una nuova versione, aggiornamento con `nt-update`
- **Cross-platform** → macOS, Linux, Windows

## 📋 Requisiti

- [Node.js](https://nodejs.org/) (>= 18)
- Un account [Cloudflare](https://dash.cloudflare.com/sign-up) (free plan basta)

L'installer si occupa di installare `wrangler` (CLI ufficiale Cloudflare) automaticamente.

## 🚀 Installazione

### macOS / Linux

```bash
git clone https://github.com/nico33t/nt-deploy.git
cd nt-deploy
chmod +x install.sh
./install.sh
```

Oppure one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/nico33t/nt-deploy/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
git clone https://github.com/nico33t/nt-deploy.git
cd nt-deploy
.\install.ps1
```

Oppure one-liner:

```powershell
irm https://raw.githubusercontent.com/nico33t/nt-deploy/main/install.ps1 | iex
```

> Se PowerShell blocca lo script:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
> ```

## 🎯 Primo utilizzo

```bash
# 1. Riapri il terminale (o ricarica la shell)
source ~/.zshrc        # macOS/Linux
. $PROFILE             # Windows PowerShell

# 2. Login Cloudflare + crea il TUO progetto
nt-init
# → ti chiede il nome (es. "nicolatomassini")
# → diventa: nicolatomassini.pages.dev

# 3. Pubblica la prima anteprima
nt-push ./dist mario-rossi
# → mario-rossi.nicolatomassini.pages.dev
```

## 📖 Comandi

| Comando | Descrizione |
|---------|-------------|
| `nt-init` | Login Cloudflare + scelta nome progetto + creazione |
| `nt-push [cartella] [cliente]` | Deploy cartella su branch cliente |
| `nt-list` | Mostra tutti i deploy |
| `nt-clients` | Lista clienti attivi |
| `nt-open [cliente]` | Apri URL nel browser |
| `nt-copy [cliente]` | Copia URL nella clipboard |
| `nt-config` | Mostra configurazione corrente |
| `nt-update` | Aggiorna nt-deploy all'ultima versione GitHub |
| `nt-version` | Mostra versione installata |
| `nt-help` | Aiuto |

## 💡 Esempi

```bash
# Deploy production (URL principale)
nt-push ./dist
# → tuoprogetto.pages.dev

# Deploy preview cliente
nt-push ./build mario-rossi
# → mario-rossi.tuoprogetto.pages.dev

# Nomi con spazi → sanitizzati automaticamente
nt-push ./dist "Hotel Roma Centrale"
# → hotel-roma-centrale.tuoprogetto.pages.dev

# Aggiorna anteprima esistente (sovrascrive)
nt-push ./dist mario-rossi

# Copia link per il cliente
nt-copy mario-rossi
# → URL nella clipboard, pronto da incollare

# Apri al volo nel browser
nt-open hotel-roma-centrale
```

## ⚙️ Configurazione

Al primo `nt-init` ti viene chiesto il nome del **tuo** progetto Cloudflare Pages. La scelta viene salvata in `~/.nt-tools/config` e usata per sempre.

```
Nome progetto [anteprima]: nicolatomassini
✓ Salvato in /Users/tuo-nome/.nt-tools/config
```

Da quel momento i deploy escono come:
- `https://nicolatomassini.pages.dev` (production)
- `https://mario-rossi.nicolatomassini.pages.dev` (cliente)

**Per cambiarlo** in seguito: rilancia `nt-init` e rispondi `s` alla domanda "Vuoi cambiarlo?".

**Override one-shot** (senza modificare il salvato):
```bash
NT_PROJECT=test nt-push ./dist                  # macOS / Linux
$env:NT_PROJECT="test"; nt-push ./dist          # Windows
```

## 🔄 Aggiornamenti

Quando lanci `nt-push`, `nt-list`, `nt-clients` o `nt-init`, lo strumento controlla in background (max una volta al giorno, con timeout di 2 secondi) se è uscita una nuova versione. Se sì, ti avvisa così:

```
💡 Nuova versione disponibile: 1.2.0 (la tua: 1.1.0)
   Aggiorna con: nt-update
```

Per aggiornare:

```bash
nt-update
```

Scarica l'ultima versione dello script da `nico33t/nt-deploy` su GitHub e sostituisce quella locale in `~/.nt-tools/`.

## 🗑️ Disinstallazione

**macOS / Linux**:
```bash
./uninstall.sh
```

**Windows**:
```powershell
.\uninstall.ps1
```

## 📁 Struttura del repo

```
nt-deploy/
├── install.sh          # Installer macOS/Linux
├── install.ps1         # Installer Windows
├── uninstall.sh        # Disinstaller macOS/Linux
├── uninstall.ps1       # Disinstaller Windows
├── scripts/
│   └── nt-deploy.sh    # Script principale
├── README.md           # 🇮🇹 Italiano
├── README.en.md        # 🇬🇧 English
└── LICENSE
```

## 🤝 Come funziona dietro le quinte

Lo script è un wrapper su [`wrangler pages deploy`](https://developers.cloudflare.com/workers/wrangler/commands/#pages) che:

1. Sanitizza il nome del cliente (lowercase, solo alfanumerico e `-`)
2. Lo usa come `--branch` di Cloudflare Pages
3. Cloudflare assegna automaticamente il sottodominio `<branch>.<progetto>.pages.dev`

Niente di più, niente di meno. Tutta la logica sta in `scripts/nt-deploy.sh` (~250 righe leggibili, dipendenza da `bash` + `curl` + `wrangler`).

## 📝 Licenza

[MIT](LICENSE) — fai quello che vuoi.

## 🐛 Problemi?

Apri una [issue](https://github.com/nico33t/nt-deploy/issues).
