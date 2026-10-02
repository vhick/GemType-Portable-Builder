$ErrorActionPreference = "Continue"

$root = $PSScriptRoot
$reportDir = Join-Path $root "Verification"
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
$report = Join-Path $reportDir ("Verify-{0}.txt" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

function W([string]$Text="") {
    Add-Content -LiteralPath $report -Value $Text -Encoding UTF8
}

W "GEMTYPE TRUE-PORTABLE VERIFICATION"
W ("Generated: {0}" -f (Get-Date))
W ("Portable folder: {0}" -f $root)
W ""

$exe = Join-Path $root "GemType-Portable.exe"
$data = Join-Path $root "Data"
$userData = Join-Path $data "UserData"
$sessionData = Join-Path $data "SessionData"

W ("EXE exists: {0}" -f (Test-Path -LiteralPath $exe -PathType Leaf))
W ("Data exists: {0}" -f (Test-Path -LiteralPath $data -PathType Container))
W ("UserData exists: {0}" -f (Test-Path -LiteralPath $userData -PathType Container))
W ("SessionData exists: {0}" -f (Test-Path -LiteralPath $sessionData -PathType Container))
W ("settings.json exists: {0}" -f (Test-Path -LiteralPath (Join-Path $userData "settings.json") -PathType Leaf))

W ""
W "=== Portable Data contents ==="
if (Test-Path -LiteralPath $data -PathType Container) {
    Get-ChildItem -LiteralPath $data -Force -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 350 |
        ForEach-Object { W $_.FullName }
}

W ""
W "=== Known host AppData residue ==="
foreach ($p in @(
    (Join-Path $env:APPDATA "GemType"),
    (Join-Path $env:APPDATA "gemtype-desktop"),
    (Join-Path $env:LOCALAPPDATA "GemType"),
    (Join-Path $env:LOCALAPPDATA "gemtype-desktop")
)) {
    W ("{0}: {1}" -f $p,(Test-Path -LiteralPath $p))
}

W ""
W "=== Registry search (read only) ==="
foreach ($term in @("GemType","org.matily.gemtype")) {
    W ("--- HKCU\Software /f {0} ---" -f $term)
    try {
        & reg.exe query HKCU\Software /f $term /s 2>&1 |
            Select-Object -First 150 |
            ForEach-Object { W ([string]$_) }
    } catch {}
}

W ""
W "API-key note:"
W "The inspected upstream desktop app stores apiKey in settings.json as plain JSON."
W "The portable build relocates that file to Data\UserData\settings.json."
W "VERIFY-PORTABLE.ps1 does not print the contents of settings.json."

Write-Host ""
Write-Host "Verification report:" -ForegroundColor Cyan
Write-Host "  $report"
