$ErrorActionPreference = "Stop"

$candidates = @(
    (Join-Path $env:APPDATA "GemType"),
    (Join-Path $env:APPDATA "gemtype-desktop")
)

$existing = @($candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Container })

Write-Host ""
Write-Host "Remove old GemType host AppData" -ForegroundColor Cyan
Write-Host ""

if ($existing.Count -eq 0) {
    Write-Host "No old GemType AppData folders were found."
    exit 0
}

Write-Host "The following folder(s) will be deleted:" -ForegroundColor Yellow
$existing | ForEach-Object { Write-Host "  $_" }

Write-Host ""
Write-Host "Only continue after the new portable build has your settings and API key."
Write-Host ""

$answer = Read-Host "Type DELETE to continue"

if ($answer -cne "DELETE") {
    Write-Host "Cancelled."
    exit 0
}

foreach ($path in $existing) {
    Remove-Item -LiteralPath $path -Recurse -Force
    Write-Host "Removed: $path" -ForegroundColor Green
}

Read-Host "Press Enter to close" | Out-Null
