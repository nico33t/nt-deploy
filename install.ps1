# nt-deploy installer (Windows)
# Uso:  .\install.ps1
# oppure: irm <url>/install.ps1 | iex

$ErrorActionPreference = "Stop"

Write-Host "🔪 nt-deploy installer" -ForegroundColor Blue
Write-Host ""

# 1. Controlla Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js non trovato" -ForegroundColor Red
    Write-Host ""
    Write-Host "Installa Node.js prima di continuare:"
    Write-Host "  • https://nodejs.org/"
    Write-Host "  • oppure: winget install OpenJS.NodeJS"
    exit 1
}
Write-Host "✓ Node.js trovato ($(node --version))" -ForegroundColor Green

# 2. Installa wrangler se manca
if (-not (Get-Command wrangler -ErrorAction SilentlyContinue)) {
    Write-Host "⚙️  Installo wrangler (Cloudflare CLI)..." -ForegroundColor Yellow
    npm install -g wrangler
}
$wranglerVersion = (wrangler --version 2>&1 | Select-Object -First 1)
Write-Host "✓ wrangler installato ($wranglerVersion)" -ForegroundColor Green

# 3. Crea cartelle
$InstallDir = Join-Path $env:USERPROFILE ".nt-tools"
$ScriptPath = Join-Path $InstallDir "nt-deploy.ps1"
$BashScriptPath = Join-Path $InstallDir "nt-deploy.sh"

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

# 4. Copia/scarica lo script bash (per chi usa Git Bash/WSL)
if (Test-Path ".\scripts\nt-deploy.sh") {
    Copy-Item ".\scripts\nt-deploy.sh" $BashScriptPath -Force
} else {
    $RepoUrl = if ($env:NT_REPO_URL) { $env:NT_REPO_URL } else { "https://raw.githubusercontent.com/nico33t/nt-deploy/main" }
    Write-Host "📥 Scarico script da $RepoUrl" -ForegroundColor Blue
    Invoke-WebRequest -Uri "$RepoUrl/scripts/nt-deploy.sh" -OutFile $BashScriptPath
}

# 5. Crea versione PowerShell nativa (per CMD/PowerShell)
$psScript = @'
# nt-deploy PowerShell wrapper
param(
    [Parameter(Position=0)][string]$Action = "help",
    [Parameter(Position=1)][string]$Arg1,
    [Parameter(Position=2)][string]$Arg2
)

$Version = "1.1.0"
$RepoRaw = "https://raw.githubusercontent.com/nico33t/nt-deploy/main"
$ConfigDir = Join-Path $env:USERPROFILE ".nt-tools"
$ConfigFile = Join-Path $ConfigDir "config.ps1"
$ScriptPath = Join-Path $ConfigDir "nt-deploy.ps1"

# Carica config persistente (env var ha priorita`)
if (-not $env:NT_PROJECT -and (Test-Path $ConfigFile)) {
    . $ConfigFile
}
$Project = if ($env:NT_PROJECT) { $env:NT_PROJECT } else { "anteprima" }

function Sanitize-Branch($name) {
    if (-not $name) { return "main" }
    $clean = $name.ToLower() -replace '[^a-z0-9-]', '-' -replace '-+', '-'
    return $clean.Trim('-')
}

function Test-Wrangler {
    if (-not (Get-Command wrangler -ErrorAction SilentlyContinue)) {
        Write-Host "❌ wrangler non trovato. Installa con: npm install -g wrangler" -ForegroundColor Red
        exit 1
    }
}

switch ($Action) {
    "push" {
        Test-Wrangler
        $folder = if ($Arg1) { $Arg1 } else { ".\dist" }
        $branch = Sanitize-Branch $Arg2
        if (-not $Arg2) { $branch = "main" }

        if (-not (Test-Path $folder -PathType Container)) {
            Write-Host "❌ Cartella '$folder' non trovata" -ForegroundColor Red
            exit 1
        }

        Write-Host "🚀 Deploy '$folder' → branch '$branch'..." -ForegroundColor Blue
        wrangler pages deploy $folder --project-name=$Project --branch=$branch --commit-dirty=true

        if ($branch -eq "main") {
            Write-Host "✅ Online: https://$Project.pages.dev" -ForegroundColor Green
        } else {
            Write-Host "✅ Online: https://$branch.$Project.pages.dev" -ForegroundColor Green
        }
    }
    "list" {
        Test-Wrangler
        Write-Host "📋 Deploy recenti:" -ForegroundColor Blue
        wrangler pages deployment list --project-name=$Project
    }
    "open" {
        $branch = Sanitize-Branch $Arg1
        if (-not $Arg1) { $branch = "main" }
        $url = if ($branch -eq "main") { "https://$Project.pages.dev" } else { "https://$branch.$Project.pages.dev" }
        Write-Host "🌐 Apro $url" -ForegroundColor Blue
        Start-Process $url
    }
    "copy" {
        $branch = Sanitize-Branch $Arg1
        if (-not $Arg1) { $branch = "main" }
        $url = if ($branch -eq "main") { "https://$Project.pages.dev" } else { "https://$branch.$Project.pages.dev" }
        Set-Clipboard -Value $url
        Write-Host "📋 $url" -ForegroundColor Green
    }
    "clients" {
        Test-Wrangler
        Write-Host "👥 Branch/clienti attivi:" -ForegroundColor Blue
        wrangler pages deployment list --project-name=$Project | Select-String "$Project.pages.dev" | Sort-Object -Unique
    }
    "init" {
        Test-Wrangler

        $skip = $false
        if ($env:NT_PROJECT) {
            Write-Host "📦 Progetto attuale: $Project" -ForegroundColor Blue
            $change = Read-Host "Vuoi cambiarlo? [s/N]"
            if ($change -notmatch '^[sSyY]$') { $skip = $true }
        }

        if (-not $skip) {
            Write-Host ""
            Write-Host "Scegli il nome del tuo progetto Cloudflare Pages."
            Write-Host "  - URL base:    <nome>.pages.dev"
            Write-Host "  - URL cliente: cliente.<nome>.pages.dev"
            Write-Host ""
            $userProject = Read-Host "Nome progetto [anteprima]"
            if (-not $userProject) { $userProject = "anteprima" }
            $userProject = Sanitize-Branch $userProject

            New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
            "`$env:NT_PROJECT = '$userProject'" | Set-Content -Path $ConfigFile -Encoding UTF8
            $Project = $userProject
            Write-Host "✓ Salvato in $ConfigFile" -ForegroundColor Green
            Write-Host ""
        }

        Write-Host "🔧 Login a Cloudflare..." -ForegroundColor Blue
        wrangler login
        Write-Host "🔧 Creo progetto '$Project' (se non esiste)..." -ForegroundColor Blue
        try { wrangler pages project create $Project --production-branch=main } catch { Write-Host "ℹ️  Progetto '$Project' gia' esistente" -ForegroundColor Yellow }
        Write-Host "✅ Pronto!" -ForegroundColor Green
        Write-Host "   nt-push .\dist              -> https://$Project.pages.dev" -ForegroundColor Blue
        Write-Host "   nt-push .\dist mario-rossi  -> https://mario-rossi.$Project.pages.dev" -ForegroundColor Blue
    }
    "config" {
        Write-Host "⚙️  Configurazione attuale:" -ForegroundColor Blue
        Write-Host "  Progetto:   $Project"
        Write-Host "  URL base:   https://$Project.pages.dev"
        if (Test-Path $ConfigFile) {
            Write-Host "  File:       $ConfigFile"
        } else {
            Write-Host "  File:       (nessuno - sto usando il default)"
        }
        Write-Host ""
        Write-Host "  Per cambiarlo: rilancia 'nt-init' e rispondi 's' alla domanda."
    }
    "update" {
        $tmp = New-TemporaryFile
        try {
            Invoke-WebRequest -Uri "$RepoRaw/install.ps1" -OutFile $tmp -UseBasicParsing -TimeoutSec 10
            $remoteVersion = (Select-String -Path $tmp -Pattern '^\$Version\s*=\s*"([^"]+)"' | Select-Object -First 1).Matches.Groups[1].Value
            if ($remoteVersion -eq $Version) {
                Write-Host "✓ Sei gia' aggiornato (v$Version)" -ForegroundColor Green
            } else {
                Write-Host "📥 Riesegui l'installer per aggiornare a v$remoteVersion :" -ForegroundColor Blue
                Write-Host "   irm $RepoRaw/install.ps1 | iex" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "❌ Check aggiornamento fallito" -ForegroundColor Red
        } finally {
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        }
    }
    "version" { Write-Host "nt-deploy v$Version" }
    default {
        @"
🔪 nt-deploy — coltellino svizzero Cloudflare Pages

COMANDI:
  nt-init                        Login Cloudflare + crea progetto
  nt-push [cartella] [cliente]   Deploy cartella su branch cliente
  nt-list                        Mostra tutti i deploy
  nt-clients                     Lista clienti attivi
  nt-open [cliente]              Apri URL nel browser
  nt-copy [cliente]              Copia URL nella clipboard
  nt-config                      Mostra configurazione
  nt-version                     Versione
  nt-help                        Questo aiuto

ESEMPI:
  nt-push .\dist mario-rossi     → mario-rossi.anteprima.pages.dev
  nt-push .\build "Hotel Roma"   → hotel-roma.anteprima.pages.dev
  nt-push .\dist                 → anteprima.pages.dev (production)
  nt-copy hotel-roma             copia link da inviare al cliente
"@
    }
}
'@

Set-Content -Path $ScriptPath -Value $psScript -Encoding UTF8
Write-Host "✓ Script installato in $ScriptPath" -ForegroundColor Green

# 6. Crea funzioni nel profilo PowerShell
$ProfileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Force -Path $ProfileDir | Out-Null
}
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Force -Path $PROFILE | Out-Null
}

$functionsBlock = @"

# >>> nt-deploy >>>
function nt-init    { & "$ScriptPath" init    @args }
function nt-push    { & "$ScriptPath" push    @args }
function nt-list    { & "$ScriptPath" list    @args }
function nt-clients { & "$ScriptPath" clients @args }
function nt-open    { & "$ScriptPath" open    @args }
function nt-copy    { & "$ScriptPath" copy    @args }
function nt-config  { & "$ScriptPath" config  @args }
function nt-update  { & "$ScriptPath" update  @args }
function nt-version { & "$ScriptPath" version @args }
function nt-help    { & "$ScriptPath" help    @args }
# <<< nt-deploy <<<
"@

$profileContent = if (Test-Path $PROFILE) { Get-Content $PROFILE -Raw } else { "" }
if ($profileContent -match ">>> nt-deploy >>>") {
    Write-Host "⚠️  Funzioni già presenti nel profilo PowerShell" -ForegroundColor Yellow
} else {
    Add-Content -Path $PROFILE -Value $functionsBlock
    Write-Host "✓ Funzioni aggiunte a $PROFILE" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 Installazione completata!" -ForegroundColor Green
Write-Host ""
Write-Host "Prossimi passi:"
Write-Host "  1. Riapri PowerShell (oppure: . `$PROFILE)" -ForegroundColor Blue
Write-Host "  2. nt-init     (login Cloudflare + crea progetto)" -ForegroundColor Blue
Write-Host "  3. nt-help     (lista comandi)" -ForegroundColor Blue
Write-Host ""
Write-Host "Nota: se PowerShell blocca lo script, esegui una volta:"
Write-Host "  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned" -ForegroundColor Yellow
