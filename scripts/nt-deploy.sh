#!/bin/bash
# nt-deploy: the web super-tool. Cloudflare Pages deploys + a full dev toolkit.
# https://github.com/nico33t/nt-deploy

VERSION="2.0.0"
REPO_RAW="https://raw.githubusercontent.com/nico33t/nt-deploy/main"

CONFIG_DIR="$HOME/.nt-tools"
CONFIG_FILE="$CONFIG_DIR/config"
SCRIPT_PATH="$CONFIG_DIR/nt-deploy.sh"
LAST_CHECK_FILE="$CONFIG_DIR/.last_update_check"
SNAP_ROOT="$CONFIG_DIR/snapshots"
SETTINGS_FILE="$CONFIG_DIR/settings"
PROJECT_FILE=".ntdeploy"
SNAP_KEEP=15

# Optional settings (API keys, tokens, flags) — written by the GUI.
# Lines use ${VAR:-value} so real environment variables still win.
[ -f "$SETTINGS_FILE" ] && source "$SETTINGS_FILE"

# ── Global flag -p/--project (any command, any position) ──────────────
_args=(); while [ $# -gt 0 ]; do case "$1" in
  -p|--project) NT_PROJECT="$2"; NT_SOURCE="flag (-p)"; shift 2;;
  --project=*) NT_PROJECT="${1#--project=}"; NT_SOURCE="flag (-p)"; shift;;
  *) _args+=("$1"); shift;;
esac; done
set -- "${_args[@]}"

# ── Project resolution ────────────────────────────────────────────────
# Order:  -p/--project  >  env NT_PROJECT  >  ./.ntdeploy  >  ~/.nt-tools/config  >  default
if [ -z "$NT_PROJECT" ] && [ -f "$PROJECT_FILE" ]; then source "$PROJECT_FILE"; NT_SOURCE="folder ($PROJECT_FILE)"; fi
if [ -z "$NT_PROJECT" ] && [ -f "$CONFIG_FILE" ]; then source "$CONFIG_FILE"; NT_SOURCE="${NT_SOURCE:-global ($CONFIG_FILE)}"; fi
PROJECT="${NT_PROJECT:-anteprima}"
NT_SOURCE="${NT_SOURCE:-default}"

ACTION=$1; shift 2>/dev/null

# ── Styling (real ESC bytes via $'...' so heredocs render too) ────────
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; BLUE=$'\033[0;34m'; YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'; MAGENTA=$'\033[0;35m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

banner() {
  echo -e "${BOLD}${CYAN}"
  echo "    ┏┓╋ ┏┫┏┓┏┓┃┏┓┓┏"
  echo -e "    ┛┗┗━┗┻┗━┣┛┗┛┗━┗┛   ⚡${NC}"
  echo -e "${BOLD} nt-deploy ${DIM}v$VERSION${NC} ${DIM}— ship your site in ${NC}${BOLD}one command${NC}${DIM}, and a lot more${NC}"
  echo -e " ${DIM}https://github.com/nico33t/nt-deploy${NC}\n"
}
err(){ echo -e "${RED}❌ $1${NC}"; }; ok(){ echo -e "${GREEN}✅ $1${NC}"; }
info(){ echo -e "${BLUE}$1${NC}"; }; warn(){ echo -e "${YELLOW}$1${NC}"; }
have(){ command -v "$1" &>/dev/null; }

# ── Utility ───────────────────────────────────────────────────────────
check_wrangler(){ have wrangler || { err "wrangler not found — npm install -g wrangler"; exit 1; }; }
need_jq(){ have jq && return 0; err "jq not found — brew install jq (or apt install jq)"; return 1; }
sanitize_branch(){ echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g;s/--*/-/g;s/^-//;s/-$//'; }
extract_version(){ grep -m1 '^VERSION=' "$1" 2>/dev/null | cut -d'"' -f2; }
url_for(){ if [ "$1" = "main" ]; then echo "https://$PROJECT.pages.dev"; else echo "https://$1.$PROJECT.pages.dev"; fi; }
deployments_json(){ wrangler pages deployment list --project-name="$PROJECT" --json 2>/dev/null; }
human_size(){ if have numfmt; then numfmt --to=iec "$1" 2>/dev/null || echo "$1 B"; else echo "$1 B"; fi; }

# ── Snapshots (kill feature: local rollback) ──────────────────────────
snap_dir(){ echo "$SNAP_ROOT/$PROJECT/$1"; }
archive_snapshot(){  # <folder> <branch>
  local folder="$1" branch="$2" dir; dir=$(snap_dir "$branch"); mkdir -p "$dir"
  local ts; ts=$(date +%s)
  tar -czf "$dir/$ts.tar.gz" -C "$folder" . 2>/dev/null || return 1
  date "+%Y-%m-%d %H:%M:%S" > "$dir/$ts.meta"
  ls -1t "$dir"/*.tar.gz 2>/dev/null | tail -n +$((SNAP_KEEP+1)) | while read -r old; do rm -f "$old" "${old%.tar.gz}.meta"; done
}

# ── Update ────────────────────────────────────────────────────────────
fetch_remote_version(){ curl -fsSL --max-time 2 "$REPO_RAW/scripts/nt-deploy.sh" 2>/dev/null | grep -m1 '^VERSION=' | cut -d'"' -f2; }
check_for_updates(){
  have curl || return 0
  if [ -f "$LAST_CHECK_FILE" ]; then
    local age; age=$(( $(date +%s) - $(stat -f %m "$LAST_CHECK_FILE" 2>/dev/null || stat -c %Y "$LAST_CHECK_FILE" 2>/dev/null || echo 0) ))
    [ "$age" -lt 86400 ] && return 0
  fi
  mkdir -p "$CONFIG_DIR"; touch "$LAST_CHECK_FILE"
  local rv; rv=$(fetch_remote_version)
  if [ -n "$rv" ] && [ "$rv" != "$VERSION" ]; then
    if [ "${NT_AUTO_UPDATE:-0}" = "1" ]; then echo ""; info "💡 Auto-update v$VERSION → v$rv…"; self_update silent
    else echo ""; warn "💡 New version available: ${GREEN}$rv${YELLOW} (yours: $VERSION)"; echo -e "   Update: ${BLUE}nt-update${NC} ${DIM}(or set NT_AUTO_UPDATE=1)${NC}"; fi
  fi
}
self_update(){
  have curl || { err "curl not found"; exit 1; }
  [ "$1" != "silent" ] && info "📥 Downloading latest version…"
  local tmp; tmp=$(mktemp)
  curl -fsSL --max-time 10 "$REPO_RAW/scripts/nt-deploy.sh" -o "$tmp" || { err "Download failed"; rm -f "$tmp"; exit 1; }
  local rv; rv=$(extract_version "$tmp")
  [ -z "$rv" ] && { err "Could not read remote version"; rm -f "$tmp"; exit 1; }
  [ "$rv" = "$VERSION" ] && { ok "Already up to date (v$VERSION)"; rm -f "$tmp"; return 0; }
  [ -f "$SCRIPT_PATH" ] || { err "Installed script not found at $SCRIPT_PATH"; rm -f "$tmp"; exit 1; }
  mv "$tmp" "$SCRIPT_PATH"; chmod +x "$SCRIPT_PATH"; ok "Updated: v$VERSION → v$rv"
}

# ── Build helpers ─────────────────────────────────────────────────────
detect_pm(){ [ -f pnpm-lock.yaml ]&&{ echo pnpm;return;}; [ -f yarn.lock ]&&{ echo yarn;return;}; [ -f bun.lockb ]&&{ echo bun;return;}; echo npm; }
detect_outdir(){ for d in dist build out .output/public public .svelte-kit/output; do [ -d "$d" ]&&{ echo "$d";return;}; done; echo ""; }
run_build(){
  [ -f package.json ] || { err "--build needs a package.json in the current folder"; exit 1; }
  local pm; pm=$(detect_pm); info "🔨 Building with ${BOLD}$pm${NC}${BLUE}…${NC}"
  if [ "$pm" = npm ]; then npm run build || { err "Build failed"; exit 1; }; else "$pm" run build || { err "Build failed"; exit 1; }; fi
}

# ══════════════════════════════════════════════════════════════════════
case $ACTION in

  # ───── DEPLOY ─────
  push)
    check_wrangler
    FOLDER=""; CLIENT=""; DO_BUILD=0; DRY=0; YES=0; OUT=""; FOLDER_SET=""
    while [ $# -gt 0 ]; do case "$1" in
      --build) DO_BUILD=1;; --dry-run) DRY=1;; -y|--yes) YES=1;;
      --out) OUT="$2"; shift;; --out=*) OUT="${1#--out=}";;
      -*) warn "⚠️  ignored flag: $1";;
      *) if [ -z "$FOLDER_SET" ]; then FOLDER="$1"; FOLDER_SET=1; else CLIENT="$1"; fi;;
    esac; shift; done

    [ "$DO_BUILD" = 1 ] && run_build
    if [ -n "$OUT" ]; then FOLDER="$OUT"
    elif [ -z "$FOLDER" ] && [ "$DO_BUILD" = 1 ]; then
      FOLDER=$(detect_outdir); [ -z "$FOLDER" ] && { err "Output folder not found after build (use --out DIR)"; exit 1; }
      info "📦 Output: ${BOLD}$FOLDER${NC}"; fi
    FOLDER=${FOLDER:-./dist}; BRANCH=$(sanitize_branch "${CLIENT:-main}")
    [ -d "$FOLDER" ] || { err "Folder '$FOLDER' not found"; exit 1; }
    ls "$FOLDER"/index.html &>/dev/null || warn "⚠️  No index.html in '$FOLDER'"
    TARGET_URL=$(url_for "$BRANCH")

    if [ "$BRANCH" = main ] && [ "$YES" != 1 ] && [ "$DRY" != 1 ]; then
      echo ""; warn "⚠️  You are about to overwrite ${BOLD}PRODUCTION${NC}${YELLOW}: $TARGET_URL"
      read -p "   Continue? [y/N] " C; [[ "$C" =~ ^[sSyY]$ ]] || { info "Cancelled."; exit 0; }
    fi
    echo ""; info "🚀 Deploying ${BOLD}$FOLDER${NC}${BLUE} → ${BOLD}$BRANCH${NC}${BLUE} (project: $PROJECT)${NC}"
    [ "$DRY" = 1 ] && { warn "   [dry-run] would deploy to: $TARGET_URL"; exit 0; }

    if wrangler pages deploy "$FOLDER" --project-name="$PROJECT" --branch="$BRANCH" --commit-dirty=true; then
      archive_snapshot "$FOLDER" "$BRANCH" && echo -e "   ${DIM}📸 snapshot saved (rollback available)${NC}"
      echo ""; ok "Live: ${BOLD}$TARGET_URL${NC}"
      have pbcopy && { echo "$TARGET_URL" | pbcopy; echo -e "   ${DIM}(URL copied to clipboard)${NC}"; }
    else code=$?; echo ""; err "Deploy failed (wrangler exit $code) — URL NOT updated"; exit "$code"; fi
    check_for_updates
    ;;

  build-push|bp) exec "$0" push --build "$@" ;;

  # ───── KILL FEATURE: local rollback ─────
  rollback)
    check_wrangler
    CLIENT="${1:-main}"; TS="$2"; BRANCH=$(sanitize_branch "$CLIENT"); DIR=$(snap_dir "$BRANCH")
    [ -d "$DIR" ] || { err "No snapshots for '$BRANCH'. Deploy at least once first."; exit 1; }
    mapfile -t SNAPS < <(ls -1t "$DIR"/*.tar.gz 2>/dev/null)
    [ "${#SNAPS[@]}" -lt 2 ] && [ -z "$TS" ] && { err "Need at least 2 snapshots to roll back (have ${#SNAPS[@]})."; exit 1; }
    if [ -n "$TS" ]; then ARCHIVE="$DIR/$TS.tar.gz"; [ -f "$ARCHIVE" ] || { err "Snapshot $TS not found. See: nt-snapshots $BRANCH"; exit 1; }
    else ARCHIVE="${SNAPS[1]}"; fi
    LBL=$(cat "${ARCHIVE%.tar.gz}.meta" 2>/dev/null || basename "$ARCHIVE")
    warn "⏪ Rolling '${BOLD}$BRANCH${NC}${YELLOW}' back to snapshot from ${BOLD}$LBL${NC}"
    read -p "   Continue? [y/N] " C; [[ "$C" =~ ^[sSyY]$ ]] || { info "Cancelled."; exit 0; }
    TMP=$(mktemp -d); tar -xzf "$ARCHIVE" -C "$TMP" || { err "Corrupt archive"; rm -rf "$TMP"; exit 1; }
    info "🚀 Redeploying snapshot…"
    if wrangler pages deploy "$TMP" --project-name="$PROJECT" --branch="$BRANCH" --commit-dirty=true; then
      archive_snapshot "$TMP" "$BRANCH"; rm -rf "$TMP"
      echo ""; ok "Rollback complete: ${BOLD}$(url_for "$BRANCH")${NC}"
    else code=$?; rm -rf "$TMP"; err "Rollback failed (exit $code)"; exit "$code"; fi
    ;;

  snapshots|snaps)
    BRANCH=$(sanitize_branch "${1:-main}"); DIR=$(snap_dir "$BRANCH")
    info "📸 Snapshots for '$BRANCH' (project: $PROJECT):"
    [ -d "$DIR" ] || { warn "   none yet."; exit 0; }
    i=0; ls -1t "$DIR"/*.tar.gz 2>/dev/null | while read -r f; do
      ts=$(basename "$f" .tar.gz); meta=$(cat "${f%.tar.gz}.meta" 2>/dev/null || echo "?")
      sz=$(human_size "$(wc -c < "$f")"); tag=""; [ $i = 0 ] && tag="${GREEN}(current)${NC}"; [ $i = 1 ] && tag="${YELLOW}(rollback →)${NC}"
      echo -e "   ${DIM}$ts${NC}  $meta  ${DIM}$sz${NC}  $tag"; i=$((i+1))
    done
    echo -e "   ${DIM}Restore with: nt-rollback $BRANCH [timestamp]${NC}"
    ;;

  # ───── MANAGE (Cloudflare) ─────
  rm|delete)
    check_wrangler; need_jq || exit 1
    CLIENT=""; YES=0; for a in "$@"; do case "$a" in -y|--yes) YES=1;; *) CLIENT="$a";; esac; done
    [ -z "$CLIENT" ] && { err "Usage: nt-rm <client> [-y]"; exit 1; }
    BRANCH=$(sanitize_branch "$CLIENT"); [ "$BRANCH" = main ] && { err "Refusing to delete production from here."; exit 1; }
    IDS=$(deployments_json | jq -r --arg b "$BRANCH" '.[] | select((.Branch|ascii_downcase)==$b) | .Id')
    [ -z "$IDS" ] && { warn "No deployments for '$BRANCH'."; exit 0; }
    N=$(echo "$IDS" | grep -c .); warn "About to delete ${BOLD}$N${NC}${YELLOW} deployment(s) for '${BOLD}$BRANCH${NC}${YELLOW}'."
    [ "$YES" != 1 ] && { read -p "   Continue? [y/N] " C; [[ "$C" =~ ^[sSyY]$ ]] || { info "Cancelled."; exit 0; }; }
    echo "$IDS" | while read -r id; do [ -z "$id" ] && continue
      if wrangler pages deployment delete "$id" --project-name="$PROJECT" --yes &>/dev/null; then echo -e "   ${GREEN}✓${NC} $id"; else echo -e "   ${RED}✗${NC} $id (maybe the live one)"; fi
    done; ok "Cleanup done."
    ;;

  logs|tail)
    check_wrangler; BRANCH=$(sanitize_branch "${1:-main}")
    if have jq; then ID=$(deployments_json | jq -r --arg b "$BRANCH" 'map(select((.Branch|ascii_downcase)==$b))|.[0].Id // empty')
      [ -z "$ID" ] && { err "No deployment for '$BRANCH'."; exit 1; }
      info "📡 Tailing '$BRANCH' ($ID) — Ctrl-C to stop"; wrangler pages deployment tail "$ID" --project-name="$PROJECT"
    else info "📡 Tailing (latest deployment)"; wrangler pages deployment tail --project-name="$PROJECT"; fi
    ;;

  rmproject|project-rm)
    check_wrangler
    NAME="${1:-}"; YES=0; [ "$2" = "-y" ] && YES=1
    [ -z "$NAME" ] && { err "Usage: nt-rmproject <project-name>"; exit 1; }
    warn "⚠️  This deletes the ENTIRE project '${BOLD}$NAME${NC}${YELLOW}' and ALL its deployments. This cannot be undone."
    if [ "$YES" != 1 ]; then
      read -p "   Type the project name to confirm: " CONF
      [ "$CONF" = "$NAME" ] || { err "Name does not match. Aborted."; exit 1; }
    fi
    if wrangler pages project delete "$NAME" --yes; then ok "Project '$NAME' deleted."
    else code=$?; err "Delete failed (exit $code)"; exit "$code"; fi
    ;;

  list)     check_wrangler; info "📋 Recent deployments ($PROJECT):"; wrangler pages deployment list --project-name="$PROJECT" ;;
  projects) check_wrangler; info "📦 Cloudflare Pages projects:"; wrangler pages project list ;;
  clients)
    check_wrangler; info "👥 Active clients/branches ($PROJECT):"
    if have jq; then deployments_json | jq -r '.[].Branch' 2>/dev/null | grep -vE '^(main|null)$' | sort -u \
        | while read -r b; do echo -e "   ${GREEN}•${NC} $b  ${DIM}→ https://$b.$PROJECT.pages.dev${NC}"; done
    else wrangler pages deployment list --project-name="$PROJECT" 2>/dev/null | grep -Eo "[a-z0-9-]+\.$PROJECT\.pages\.dev" | sed -E "s#\.$PROJECT\.pages\.dev##" | grep -v "^$PROJECT$" | sort -u; fi
    ;;
  open) URL=$(url_for "$(sanitize_branch "${1:-main}")"); info "🌐 $URL"; if have open; then open "$URL"; elif have xdg-open; then xdg-open "$URL"; else echo "$URL"; fi ;;
  copy) URL=$(url_for "$(sanitize_branch "${1:-main}")"); if have pbcopy; then echo "$URL"|pbcopy; elif have xclip; then echo "$URL"|xclip -selection clipboard; else warn "⚠️ clipboard unavailable"; fi; ok "📋 $URL" ;;

  # ───── PAGESPEED PRE-TEST (Google Lighthouse engine, same as pagespeed.web.dev) ─────
  audit|pagespeed|test)
    A="${1:-main}"; STRAT="${2:-mobile}"
    case "$A" in http*) URL="$A";; *) URL=$(url_for "$(sanitize_branch "$A")");; esac
    need_jq || exit 1; have curl || { err "curl missing"; exit 1; }
    ENC=$(jq -rn --arg u "$URL" '$u|@uri')
    API="https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=$ENC&strategy=$STRAT&category=PERFORMANCE&category=ACCESSIBILITY&category=BEST_PRACTICES&category=SEO"
    [ -n "$NT_PSI_KEY" ] && API="$API&key=$NT_PSI_KEY"
    info "🔬 PageSpeed (Google Lighthouse engine) — ${BOLD}$URL${NC}${BLUE}  [$STRAT]${NC}"
    echo -e "   ${DIM}analyzing (~20-40s)…${NC}"
    RESP=$(curl -sS --max-time 90 -w $'\n%{http_code}' "$API" 2>/dev/null); CODE="${RESP##*$'\n'}"; J="${RESP%$'\n'*}"
    if [ "$CODE" = 429 ]; then
      err "Google anonymous quota exceeded (HTTP 429)."
      echo -e "   Retry shortly, or use a ${BOLD}free${NC} API key:"
      echo -e "   ${BLUE}export NT_PSI_KEY=...${NC}  ${DIM}(console.cloud.google.com → PageSpeed Insights API)${NC}"
      exit 1
    fi
    { [ "$CODE" -ge 400 ] 2>/dev/null || [ -z "$CODE" ]; } && { err "PSI request failed (HTTP ${CODE:-?}): $(echo "$J"|jq -r '.error.message? // "network"' 2>/dev/null)"; exit 1; }
    bar(){ local s=$1 c=$RED n i fill="" emp=""; [ "$s" -ge 90 ]&&c=$GREEN||{ [ "$s" -ge 50 ]&&c=$YELLOW; }; n=$((s/5))
      for((i=0;i<n;i++));do fill+=█;done; for((i=n;i<20;i++));do emp+=░;done
      printf "${c}%s${DIM}%s${NC} ${c}${BOLD}%3s${NC}\n" "$fill" "$emp" "$s"; }
    P=$(echo "$J"|jq -r '(.lighthouseResult.categories.performance.score*100|round)')
    AC=$(echo "$J"|jq -r '(.lighthouseResult.categories.accessibility.score*100|round)')
    BP=$(echo "$J"|jq -r '(.lighthouseResult.categories["best-practices"].score*100|round)')
    SE=$(echo "$J"|jq -r '(.lighthouseResult.categories.seo.score*100|round)')
    echo ""; printf "   Performance     "; bar "$P"; printf "   Accessibility   "; bar "$AC"
    printf "   Best Practices  "; bar "$BP"; printf "   SEO             "; bar "$SE"
    echo ""; info "   Core Web Vitals:"
    for m in "first-contentful-paint:FCP" "largest-contentful-paint:LCP" "total-blocking-time:TBT" "cumulative-layout-shift:CLS" "speed-index:Speed Index"; do
      k="${m%%:*}"; lbl="${m##*:}"; v=$(echo "$J"|jq -r --arg k "$k" '.lighthouseResult.audits[$k].displayValue // "—"')
      printf "     ${BOLD}%-12s${NC} %s\n" "$lbl" "$v"
    done
    echo -e "   ${DIM}desktop run: nt-audit $A desktop  ·  same engine as pagespeed.web.dev${NC}"
    ;;

  # ───── ANALYTICS / TRAFFIC ─────
  analytics|stats)
    SUB="${1:-help}"; [ "$ACTION" = stats ] && SUB="stats" || shift 2>/dev/null
    case "$SUB" in
      inject)
        FOLDER="${1:-.}"; TOKEN="${2:-$NT_CF_BEACON}"
        [ -d "$FOLDER" ] || { err "Folder '$FOLDER' not found"; exit 1; }
        [ -z "$TOKEN" ] && { err "Need a Web Analytics token: nt-analytics inject <folder> <token>"; echo "   Create it: dash.cloudflare.com → Web Analytics → Add a site"; exit 1; }
        SNIP="<script defer src=\"https://static.cloudflareinsights.com/beacon.min.js\" data-cf-beacon='{\"token\":\"$TOKEN\"}'></script>"
        C=0; while IFS= read -r f; do
          grep -q "static.cloudflareinsights.com/beacon" "$f" && continue
          grep -qi "</body>" "$f" || continue
          awk -v s="$SNIP" '{ if(!d && tolower($0) ~ /<\/body>/){ sub(/<\/body>/, s"\n</body>"); d=1 } print }' "$f" > "$f.nt" && mv "$f.nt" "$f"; C=$((C+1))
        done < <(find "$FOLDER" -type f -name '*.html')
        ok "Beacon injected into $C file(s). Redeploy to start tracking."
        ;;
      open) U="https://dash.cloudflare.com/?to=/:account/web-analytics"; info "🌐 Opening Web Analytics: $U"; have open&&open "$U"||echo "$U" ;;
      stats)
        info "📊 Traffic stats (Cloudflare Web Analytics) — project: $PROJECT"
        if [ -z "$NT_CF_TOKEN" ] || [ -z "$NT_CF_ACCOUNT" ] || [ -z "$NT_CF_SITETAG" ]; then
          warn "   CLI stats need 3 env vars (one-time setup):"
          echo -e "     ${BLUE}export NT_CF_TOKEN=...${NC}    ${DIM}# API token with Analytics:Read${NC}"
          echo -e "     ${BLUE}export NT_CF_ACCOUNT=...${NC}  ${DIM}# Account ID${NC}"
          echo -e "     ${BLUE}export NT_CF_SITETAG=...${NC}  ${DIM}# site tag (from the beacon)${NC}"
          echo -e "   Or open the dashboard:  ${BLUE}nt-analytics open${NC}"
          exit 0
        fi
        need_jq || exit 1
        SINCE=$(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)
        UNTIL=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        Q=$(jq -nc --arg a "$NT_CF_ACCOUNT" --arg t "$NT_CF_SITETAG" --arg s "$SINCE" --arg u "$UNTIL" \
          '{query:"query($a:String!,$t:String!,$s:Time!,$u:Time!){viewer{accounts(filter:{accountTag:$a}){rumPageloadEventsAdaptiveGroups(limit:1,filter:{siteTag:$t,datetime_geq:$s,datetime_leq:$u}){count sum{visits}}}}}",variables:{a:$a,t:$t,s:$s,u:$u}}')
        R=$(curl -fsSL --max-time 20 -H "Authorization: Bearer $NT_CF_TOKEN" -H "Content-Type: application/json" -d "$Q" https://api.cloudflare.com/client/v4/graphql) \
          || { err "API request failed."; exit 1; }
        echo "$R" | jq -e '.errors and (.errors|length>0)' >/dev/null 2>&1 && { err "API: $(echo "$R"|jq -r '.errors[0].message')"; exit 1; }
        G=$(echo "$R"|jq -r '.data.viewer.accounts[0].rumPageloadEventsAdaptiveGroups[0]')
        PV=$(echo "$G"|jq -r '.count // 0'); VS=$(echo "$G"|jq -r '.sum.visits // 0')
        echo -e "   Last 7 days →  Page views: ${BOLD}$PV${NC}   Visits: ${BOLD}$VS${NC}"
        ;;
      *) echo "Usage: nt-analytics inject <folder> <token> | open | stats" ;;
    esac
    ;;

  # ───── CLIENT NOTES ─────
  notes|note)
    CLIENT="${1:-}"; [ -z "$CLIENT" ] && { err "Usage: nt-notes <client> [\"note text\"]"; exit 1; }
    B=$(sanitize_branch "$CLIENT"); ND="$CONFIG_DIR/notes/$PROJECT"; mkdir -p "$ND"; F="$ND/$B.md"
    shift; TEXT="$*"
    if [ -n "$TEXT" ]; then echo "- [$(date '+%Y-%m-%d %H:%M')] $TEXT" >> "$F"; ok "Note added for '$B'."
    else info "🗒  Notes for '$B' (project: $PROJECT):"; [ -s "$F" ] && sed 's/^/   /' "$F" || warn "   no notes yet. Add one: nt-notes $B \"...\""; fi
    ;;

  # ───── TOOLKIT (works WITHOUT Cloudflare too) ─────
  serve)
    DIR="${1:-.}"; PORT="${2:-8080}"; [ -d "$DIR" ] || { err "Folder '$DIR' not found"; exit 1; }
    info "🖥  Local server: ${BOLD}http://localhost:$PORT${NC}${BLUE}  (Ctrl-C to stop)${NC}"
    if have python3; then (cd "$DIR" && python3 -m http.server "$PORT")
    elif have npx; then npx --yes serve -l "$PORT" "$DIR"
    else err "Need python3 or npx"; exit 1; fi
    ;;

  new)
    NAME="${1:-site}"; SAFE=$(sanitize_branch "$NAME")
    [ -e "$SAFE" ] && { err "'$SAFE' already exists"; exit 1; }
    mkdir -p "$SAFE"
    cat > "$SAFE/index.html" <<HTML
<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>$NAME</title><link rel="stylesheet" href="styles.css"></head>
<body><main><h1>$NAME</h1><p>Made with nt-deploy. Ready to ship.</p>
<button id="b">Hello 👋</button></main><script src="app.js"></script></body></html>
HTML
    cat > "$SAFE/styles.css" <<'CSS'
*{margin:0;box-sizing:border-box}body{min-height:100dvh;display:grid;place-items:center;
font-family:system-ui,sans-serif;background:#0b1020;color:#e6f0ff}
main{text-align:center;padding:2rem}h1{font-size:clamp(2rem,8vw,4rem)}
button{margin-top:1.5rem;padding:.8rem 1.6rem;border:0;border-radius:10px;cursor:pointer;
background:linear-gradient(120deg,#35e8ff,#8b6cff);color:#04060f;font-weight:700}
CSS
    echo "document.getElementById('b').onclick=()=>alert('Deploy with: nt-push $SAFE');" > "$SAFE/app.js"
    echo "NT_PROJECT=$PROJECT" > "$SAFE/.ntdeploy"
    ok "Created ${BOLD}$SAFE/${NC}"; echo -e "   ${DIM}nt-serve $SAFE   ·   nt-push $SAFE $SAFE${NC}"
    ;;

  build)   run_build; OUT=$(detect_outdir); [ -n "$OUT" ] && { ok "Build ready in ${BOLD}$OUT${NC}"; exec "$0" size "$OUT"; } ;;

  size)
    DIR="${1:-$(detect_outdir)}"; DIR="${DIR:-./dist}"; [ -d "$DIR" ] || { err "Folder '$DIR' not found"; exit 1; }
    info "📏 Size of ${BOLD}$DIR${NC}:"
    echo -e "   Total: ${BOLD}$(du -sh "$DIR" 2>/dev/null | cut -f1)${NC}   Files: $(find "$DIR" -type f | wc -l | tr -d ' ')"
    echo -e "   ${DIM}Top 8 files:${NC}"
    find "$DIR" -type f -exec du -h {} + 2>/dev/null | sort -rh | head -8 | sed 's/^/   /'
    ;;

  zip)
    DIR="${1:-$(detect_outdir)}"; DIR="${DIR:-.}"; OUT="${2:-$(basename "$(cd "$DIR"&&pwd)")-$(date +%Y%m%d).zip}"
    [ -d "$DIR" ] || { err "Folder '$DIR' not found"; exit 1; }; have zip || { err "'zip' not found"; exit 1; }
    (cd "$DIR" && zip -rq "$OLDPWD/$OUT" . -x '*.DS_Store' 'node_modules/*' '.git/*'); ok "Created ${BOLD}$OUT${NC} ($(human_size "$(wc -c < "$OUT")"))"
    ;;

  check)
    A="${1:-main}"; case "$A" in http*) URL="$A";; *) URL=$(url_for "$(sanitize_branch "$A")");; esac
    have curl || { err "curl not found"; exit 1; }; info "🩺 Checking ${BOLD}$URL${NC}"
    read -r code ttime size < <(curl -kso /dev/null -w '%{http_code} %{time_total} %{size_download}' "$URL")
    C=$RED; [ "$code" -ge 200 ] 2>/dev/null && [ "$code" -lt 400 ] && C=$GREEN
    echo -e "   Status: ${C}${BOLD}$code${NC}   Time: ${BOLD}${ttime}s${NC}   Size: ${BOLD}$(human_size "${size:-0}")${NC}"
    ;;

  qr)
    A="${1:-main}"; case "$A" in http*) URL="$A";; *) URL=$(url_for "$(sanitize_branch "$A")");; esac
    info "🔳 QR for ${BOLD}$URL${NC}"
    if have qrencode; then qrencode -t ANSIUTF8 "$URL"
    elif have npx; then npx --yes qrcode-terminal "$URL"
    else warn "Install qrencode (brew install qrencode) for the QR."; echo "   $URL"; fi
    ;;

  doctor)
    banner; info "🩺 Environment check:"
    chk(){ if have "$1"; then echo -e "   ${GREEN}✓${NC} $1 ${DIM}$($1 --version 2>/dev/null|head -1)${NC}"; else echo -e "   ${RED}✗${NC} $1 ${DIM}(missing)${NC}"; fi; }
    chk node; chk npm; chk wrangler; chk git; chk jq; chk curl; chk qrencode; chk python3
    echo ""; echo -e "   Project: ${BOLD}$PROJECT${NC} ${DIM}[$NT_SOURCE]${NC}"
    if have wrangler; then who=$(wrangler whoami 2>/dev/null | grep -i -m1 'email\|account' | sed 's/^/   /'); [ -n "$who" ] && echo -e "${DIM}$who${NC}" || echo -e "   ${YELLOW}Cloudflare: not logged in (nt-init)${NC}"; fi
    ;;

  clean)
    info "🧹 Cleaning build artifacts in the current folder:"
    TARGETS=(dist build out .output .svelte-kit .wrangler .turbo node_modules/.cache .next/cache)
    FOUND=(); for t in "${TARGETS[@]}"; do [ -e "$t" ] && FOUND+=("$t"); done
    [ "${#FOUND[@]}" = 0 ] && { ok "Already clean."; exit 0; }
    printf '   %s\n' "${FOUND[@]}"; read -p "   Delete? [y/N] " C; [[ "$C" =~ ^[sSyY]$ ]] || { info "Cancelled."; exit 0; }
    rm -rf "${FOUND[@]}"; ok "Clean."
    ;;

  # ───── KILL COMBO: ship ─────
  ship)
    CLIENT="${1:-main}"; info "📦 SHIP → build + deploy + QR + open"
    [ -f package.json ] && "$0" push --build "$CLIENT" -y || "$0" push . "$CLIENT" -y
    "$0" qr "$CLIENT"; "$0" open "$CLIENT"
    ;;

  # ───── GUI ─────
  gui)
    if [ "$1" = dns ]; then
      if grep -qE "^[^#]*[[:space:]]nt\.local([[:space:]]|$)" /etc/hosts 2>/dev/null; then ok "nt.local is already configured."; else
        info "To always open the GUI at ${BOLD}http://nt.local:7700${NC}${BLUE}, run once:${NC}"
        echo -e "   ${BLUE}echo '127.0.0.1 nt.local' | sudo tee -a /etc/hosts${NC}"
      fi; exit 0
    fi
    PORT="${1:-7700}"; GUI="$CONFIG_DIR/nt-gui.py"; [ -f "$GUI" ] || GUI="$(dirname "$0")/nt-gui.py"
    [ -f "$GUI" ] || { err "nt-gui.py not found"; exit 1; }
    have python3 || { err "python3 required"; exit 1; }
    HOST=localhost
    if grep -qE "^[^#]*[[:space:]]nt\.local([[:space:]]|$)" /etc/hosts 2>/dev/null; then HOST=nt.local
    else warn "💡 Tip: open it at nt.local with  ${BLUE}nt-gui dns${NC}${YELLOW} (one-time setup)"; fi
    URL="http://$HOST:$PORT"
    info "🪟 GUI → ${BOLD}$URL${NC}${BLUE}  (Ctrl-C to stop)${NC}"
    have open && (sleep 1; open "$URL") &
    NT_PROJECT="$PROJECT" NT_SCRIPT="$(cd "$(dirname "$0")"&&pwd)/$(basename "$0")" python3 "$GUI" "$PORT"
    ;;

  # ───── SETUP ─────
  init)
    check_wrangler; banner
    if [ -n "${NT_PROJECT:-}" ]; then info "📦 Project: ${GREEN}$PROJECT${NC} ${DIM}[$NT_SOURCE]${NC}"; read -p "Change it? [y/N] " CH; [[ "$CH" =~ ^[sSyY]$ ]] || SKIP=1; fi
    if [ -z "${SKIP:-}" ]; then echo ""; echo "Cloudflare Pages project name:"; echo -e "  • base:   ${YELLOW}<name>.pages.dev${NC}"; echo -e "  • client: ${YELLOW}client.<name>.pages.dev${NC}"; echo ""
      read -p "Name [anteprima]: " UP; UP=$(sanitize_branch "${UP:-anteprima}"); mkdir -p "$CONFIG_DIR"; echo "NT_PROJECT=$UP" > "$CONFIG_FILE"; PROJECT="$UP"; ok "Saved to $CONFIG_FILE"; echo ""; fi
    info "🔧 Cloudflare login…"; wrangler login
    info "🔧 Creating project '$PROJECT'…"; wrangler pages project create "$PROJECT" --production-branch=main 2>/dev/null || warn "ℹ️  '$PROJECT' already exists, reusing it"
    echo ""; ok "Ready!"; echo -e "   ${BLUE}nt-push ./dist${NC} → https://$PROJECT.pages.dev"; echo -e "   ${BLUE}nt-ship${NC}        → build + deploy + QR + open"
    check_for_updates
    ;;
  config)
    info "⚙️  Configuration:"; echo "  Project:     $PROJECT  [$NT_SOURCE]"; echo "  Base URL:    https://$PROJECT.pages.dev"
    echo "  Snapshots:   $SNAP_ROOT/$PROJECT  (keep last $SNAP_KEEP)"; echo "  Auto-update: ${NT_AUTO_UPDATE:-0}"
    echo -e "  ${DIM}Global: nt-init  ·  per-repo: a .ntdeploy file with NT_PROJECT=name${NC}"
    ;;
  version|--version|-v) echo "nt-deploy v$VERSION" ;;
  update) self_update ;;

  help|--help|-h|"")
    banner
    cat <<EOF
${BOLD}DEPLOY${NC}
  nt-push [dir] [client]     Deploy a folder (default ./dist → production)
  nt-push --build [client]   Build (npm/pnpm/yarn/bun) + deploy automatically
  nt-push … --dry-run / -y   Simulate / skip production confirmation
  nt-ship [client]           ${MAGENTA}★${NC} build + deploy + QR + open, all in one
  nt-bp [client]             Shortcut for 'nt-push --build'

${BOLD}TIME MACHINE${NC} ${MAGENTA}(kill feature)${NC}
  nt-rollback [client] [ts]  Restore a previous deploy (impossible with wrangler alone!)
  nt-snapshots [client]      List local snapshots

${BOLD}MANAGE${NC}
  nt-list / nt-clients / nt-projects   Deployments, clients, projects
  nt-rm <client> [-y]        Delete a client's deployments (asks to confirm)
  nt-rmproject <name>        Delete a whole project (retype name to confirm)
  nt-logs [client]           Live log tail
  nt-open / nt-copy [client]  Open / copy the URL

${BOLD}QUALITY & TRAFFIC${NC}
  nt-audit [url|client] [mobile|desktop]   PageSpeed pre-test with score (Google engine)
  nt-analytics inject <dir> <token>        Enable visit tracking (Web Analytics)
  nt-analytics open | nt-stats             Open dashboard / show visits

${BOLD}TOOLKIT${NC} ${DIM}(works without Cloudflare too)${NC}
  nt-serve [dir] [port]      Local static server
  nt-new [name]              Scaffold a starter site, ready to deploy
  nt-build                   Run the build and show its size
  nt-size [dir]              Output weight report + top files
  nt-zip [dir] [out.zip]     Package a folder
  nt-check [url|client]      Health-check: HTTP status, time, size
  nt-qr [url|client]         QR code in the terminal
  nt-clean                   Remove dist/build/cache
  nt-doctor                  Environment diagnostics
  nt-notes <client> ["…"]    Per-client notes (view/add)
  nt-gui [port]              Lightweight browser GUI

${BOLD}SETUP${NC}
  nt-init · nt-config · nt-update · nt-version

${DIM}Tip: 'nt <command>' (e.g. nt ship) · project: -p <name> · auto-update: NT_AUTO_UPDATE=1${NC}
EOF
    ;;
  *) err "Unknown command: $ACTION"; echo "Run 'nt-help' for the list"; exit 1 ;;
esac
