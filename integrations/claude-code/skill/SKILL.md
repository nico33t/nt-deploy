---
name: nt-deploy
description: Use to scaffold, preview, audit, deploy and roll back static websites with the nt-deploy CLI. Trigger when the user wants to create a new client/site base (nt-create), deploy to Cloudflare Pages (nt-push/nt-ship), roll back a deploy (nt-rollback), run a PageSpeed audit (nt-audit), convert images to WebP (nt-images), pull a brand DESIGN.md (nt-design), or open the GUI (nt-gui). Also triggers on "create a site for client X", "deploy this", "publish to Cloudflare", "rollback", "lighthouse/pagespeed score".
---

# nt-deploy

CLI installed at `~/.nt-tools/nt-deploy.sh` (aliases `nt-*` and `nt <command>`). Cloudflare Pages + dev toolkit.

## Scaffold a client site (most common)
Non-interactive (use flags so it doesn't prompt):
```bash
~/.nt-tools/nt-deploy.sh create <client> --plain --no-serve   # HTML/CSS/JS base
~/.nt-tools/nt-deploy.sh create <client> --vite  --no-serve   # Vite + HMR
```
Folder name = sanitized client name. Generates: index.html, styles.css, app.js,
DESIGN.md (9-section spec — empty, ask the user to fill it), AGENTS.md, CLAUDE.md,
_headers, robots.txt, sitemap.xml, site.webmanifest, favicon.svg, 404.html.

Before/after scaffolding, also **ask the user whether to start a live-reload dev server**.
If yes: `~/.nt-tools/nt-deploy.sh serve <dir>` (plain) or `cd <dir> && npm install && npm run dev`
(Vite). You can also pass `--serve` to `create` to start it automatically.

After scaffolding, read the new `DESIGN.md` and ask the user the questions in its
"Agent Prompt Guide" before generating any UI. **If the user can't or doesn't want to
answer** (e.g. "propose it yourself", "give me a base"), don't stall: offer a base to draw
from — either propose sensible defaults and write them into `DESIGN.md`, or fetch a ready
brand template with `nt-design add <brand>` (e.g. stripe, linear, notion). Always fill
`DESIGN.md` first, then build against it; never invent values silently.

## Other commands
- Preview: `nt-serve <dir>` · Deploy: `nt-push <dir> <client>` · All-in-one: `nt-ship <client>`
- Rollback: `nt-rollback <client>` · Snapshots: `nt-snapshots <client>`
- Audit (PageSpeed): `nt-audit <url|client>` · Images→WebP: `nt-images <dir>`
- Brand template: `nt-design add <brand>` · GUI: `nt-gui` · Diagnostics: `nt-doctor`
- Target a project: append `-p <project>`. Full list: `nt-help`.

## Notes
- Deploy/rollback are non-interactive with `-y`; production overwrite asks to confirm.
- Needs `wrangler` (Cloudflare). `nt-init` logs in and creates the project.
