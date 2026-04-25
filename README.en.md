# 🔪 nt-deploy

[🇮🇹 Italiano](README.md) · **🇬🇧 English**

A terminal Swiss-army knife for shipping static previews to **Cloudflare Pages** with a single command. Each client gets their own dynamic subdomain — no hosting setup, no DNS, no Git repo required.

```bash
nt-push ./dist mario-rossi
# ✅ Online: https://mario-rossi.studio-acme.pages.dev
```

> The base domain (`studio-acme.pages.dev` above) is **yours** — you pick it the first time you run `nt-init`. Every user has their own: whoever installs nt-deploy decides what their personal "preview space" is called (e.g. `johndoe.pages.dev`, `acmestudio.pages.dev`, `previews.pages.dev`...).

## ✨ What it does

- **Instant deploy** of any static folder (React/Vue/Astro builds, Next export, raw HTML…)
- **Per-client dynamic subdomains** → every client gets a shareable URL
- **Easy updates** → re-run the same command, the preview updates on the same URL
- **Quick utilities** → `nt-copy mario-rossi` to put the link on your clipboard, ready to paste in a chat
- **Self-update** → tells you when a new version is out, one-command update via `nt-update`
- **Cross-platform** → macOS, Linux, Windows

## 📋 Requirements

- [Node.js](https://nodejs.org/) (>= 18)
- A [Cloudflare](https://dash.cloudflare.com/sign-up) account (free plan is enough)

The installer takes care of installing `wrangler` (Cloudflare's official CLI) automatically.

## 🚀 Installation

### macOS / Linux

```bash
git clone https://github.com/nico33t/nt-deploy.git
cd nt-deploy
chmod +x install.sh
./install.sh
```

Or one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/nico33t/nt-deploy/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
git clone https://github.com/nico33t/nt-deploy.git
cd nt-deploy
.\install.ps1
```

Or one-liner:

```powershell
irm https://raw.githubusercontent.com/nico33t/nt-deploy/main/install.ps1 | iex
```

> If PowerShell blocks the script:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
> ```

## 🎯 First run

```bash
# 1. Reload your shell
source ~/.zshrc        # macOS/Linux
. $PROFILE             # Windows PowerShell

# 2. Cloudflare login + create YOUR project
nt-init
# → asks for the name (e.g. "johndoe")
# → becomes: johndoe.pages.dev

# 3. Ship the first preview
nt-push ./dist mario-rossi
# → mario-rossi.johndoe.pages.dev
```

## 📖 Commands

| Command | Description |
|---------|-------------|
| `nt-init` | Cloudflare login + project name picker + project creation |
| `nt-push [folder] [client]` | Deploy folder to a client branch |
| `nt-list` | Show all deployments |
| `nt-clients` | List active clients |
| `nt-open [client]` | Open URL in the browser |
| `nt-copy [client]` | Copy URL to the clipboard |
| `nt-config` | Show current configuration |
| `nt-update` | Update nt-deploy to the latest GitHub version |
| `nt-version` | Show installed version |
| `nt-help` | Help |

## 💡 Examples

```bash
# Production deploy (main URL)
nt-push ./dist
# → yourproject.pages.dev

# Client preview deploy
nt-push ./build mario-rossi
# → mario-rossi.yourproject.pages.dev

# Names with spaces → auto-sanitized
nt-push ./dist "Hotel Roma Centrale"
# → hotel-roma-centrale.yourproject.pages.dev

# Update an existing preview (overwrites)
nt-push ./dist mario-rossi

# Copy the client link
nt-copy mario-rossi
# → URL on the clipboard, ready to paste

# Open in the browser
nt-open hotel-roma-centrale
```

## ⚙️ Configuration

The first time you run `nt-init` it asks for **your** Cloudflare Pages project name. The choice is saved to `~/.nt-tools/config` and used from then on.

```
Project name [anteprima]: johndoe
✓ Saved to /Users/your-name/.nt-tools/config
```

From that moment, deploys produce:
- `https://johndoe.pages.dev` (production)
- `https://mario-rossi.johndoe.pages.dev` (client)

**To change it later**: re-run `nt-init` and answer `s` (yes) to the "Change it?" prompt.

**One-shot override** (without touching the saved value):
```bash
NT_PROJECT=test nt-push ./dist                  # macOS / Linux
$env:NT_PROJECT="test"; nt-push ./dist          # Windows
```

## 🔄 Updates

When you run `nt-push`, `nt-list`, `nt-clients` or `nt-init`, the tool checks in the background (at most once a day, 2-second timeout) whether a new version was released. If so, it tells you:

```
💡 New version available: 1.2.0 (yours: 1.1.0)
   Update with: nt-update
```

To update:

```bash
nt-update
```

It pulls the latest script from `nico33t/nt-deploy` on GitHub and replaces the local one in `~/.nt-tools/`.

## 🗑️ Uninstall

**macOS / Linux**:
```bash
./uninstall.sh
```

**Windows**:
```powershell
.\uninstall.ps1
```

## 📁 Repo layout

```
nt-deploy/
├── install.sh          # macOS/Linux installer
├── install.ps1         # Windows installer
├── uninstall.sh        # macOS/Linux uninstaller
├── uninstall.ps1       # Windows uninstaller
├── scripts/
│   └── nt-deploy.sh    # Main script
├── README.md           # 🇮🇹 Italiano
├── README.en.md        # 🇬🇧 English
└── LICENSE
```

## 🤝 How it works under the hood

The script is a wrapper around [`wrangler pages deploy`](https://developers.cloudflare.com/workers/wrangler/commands/#pages) that:

1. Sanitizes the client name (lowercase, alphanumeric + `-`)
2. Passes it as `--branch` to Cloudflare Pages
3. Cloudflare automatically allocates the `<branch>.<project>.pages.dev` subdomain

That's it. The whole thing lives in `scripts/nt-deploy.sh` (~250 readable lines, depends on `bash` + `curl` + `wrangler`).

## 📝 License

[MIT](LICENSE) — do whatever you want.

## 🐛 Issues?

Open an [issue](https://github.com/nico33t/nt-deploy/issues).
