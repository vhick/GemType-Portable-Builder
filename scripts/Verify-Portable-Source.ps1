param(
    [Parameter(Mandatory=$true)]
    [string]$SourceRoot
)

$ErrorActionPreference = "Stop"

$mainFile = Join-Path $SourceRoot "desktop\main.js"
$packageFile = Join-Path $SourceRoot "desktop\package.json"

$main = Get-Content -LiteralPath $mainFile -Raw
$package = Get-Content -LiteralPath $packageFile -Raw | ConvertFrom-Json

$required = @(
    "GEMTYPE_PORTABLE_PATHS_V1",
    "PORTABLE_EXECUTABLE_DIR",
    "app.setPath('userData'",
    "app.setPath('sessionData'",
    "app.setPath('logs'",
    "app.setPath('crashDumps'"
)

foreach ($needle in $required) {
    if ($main.IndexOf($needle,[StringComparison]::Ordinal) -lt 0) {
        throw "Portable source verification failed: missing $needle"
    }
}

# The inspected upstream stores every desktop setting, including the Gemini
# API key, in settings.json below userData. Make sure that is still true.
foreach ($needle in @(
    "path.join(app.getPath('userData'), 'settings.json')",
    "apiKey",
    "fs.writeFileSync(settingsPath()"
)) {
    if ($main.IndexOf($needle,[StringComparison]::Ordinal) -lt 0) {
        throw "GemType settings implementation changed upstream: missing $needle"
    }
}

# Fail if a future version introduces a separate system secret backend that
# this patch does not account for.
foreach ($unexpected in @(
    "safeStorage",
    "keytar",
    "setLoginItemSettings",
    "electron-updater",
    "autoUpdater"
)) {
    if ($main.IndexOf($unexpected,[StringComparison]::OrdinalIgnoreCase) -ge 0) {
        throw "Upstream introduced '$unexpected'. Re-inspection is required before declaring the build portable."
    }
}

Write-Host ""
Write-Host "Portable source verification PASS." -ForegroundColor Green
Write-Host "Settings/API key: Data\UserData\settings.json"
Write-Host "Chromium/session data: Data\SessionData"
Write-Host "Logs: Data\Logs"
Write-Host "Crash dumps: Data\CrashDumps"
