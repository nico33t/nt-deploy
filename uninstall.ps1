# nt-deploy uninstaller (Windows)

Write-Host "🗑️  Disinstallo nt-deploy..." -ForegroundColor Yellow

$InstallDir = Join-Path $env:USERPROFILE ".nt-tools"
if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
    Write-Host "✓ Cartella $InstallDir rimossa" -ForegroundColor Green
}

if (Test-Path $PROFILE) {
    $content = Get-Content $PROFILE -Raw
    if ($content -match ">>> nt-deploy >>>") {
        $cleaned = $content -replace "(?s)\r?\n?# >>> nt-deploy >>>.*?# <<< nt-deploy <<<\r?\n?", ""
        Set-Content -Path $PROFILE -Value $cleaned -NoNewline
        Write-Host "✓ Funzioni rimosse da $PROFILE" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "✅ Disinstallazione completata" -ForegroundColor Green
Write-Host "Riapri PowerShell per applicare i cambiamenti"
