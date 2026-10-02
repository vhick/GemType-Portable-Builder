$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$target = Join-Path $root "Data\UserData"
$backupRoot = Join-Path $root "MigrationBackups"

$candidates = @(
    (Join-Path $env:APPDATA "GemType"),
    (Join-Path $env:APPDATA "gemtype-desktop")
)

$source = $null

foreach ($candidate in $candidates) {
    if (Test-Path -LiteralPath (Join-Path $candidate "settings.json") -PathType Leaf) {
        $source = $candidate
        break
    }
}

Write-Host ""
Write-Host "GemType settings migration" -ForegroundColor Cyan
Write-Host ""

if (-not $source) {
    Write-Host "No official GemType settings.json was found in the expected AppData locations." -ForegroundColor Yellow
    Write-Host "Nothing was changed."
    exit 0
}

Write-Host "Source:"
Write-Host "  $source"
Write-Host "Target:"
Write-Host "  $target"
Write-Host ""

New-Item -ItemType Directory -Path $target,$backupRoot -Force | Out-Null

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $backupRoot "GemType-$stamp"

Write-Host "Making safety backup..."
& robocopy.exe "$source" "$backup" /E /COPY:DAT /DCOPY:DAT /R:1 /W:1 /XJ /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -gt 7) {
    throw "Backup failed. Robocopy exit code: $LASTEXITCODE"
}

Write-Host "Copying settings into portable UserData..."
& robocopy.exe "$source" "$target" /E /COPY:DAT /DCOPY:DAT /R:1 /W:1 /XJ /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -gt 7) {
    throw "Migration failed. Robocopy exit code: $LASTEXITCODE"
}

Write-Host ""
Write-Host "Migration completed." -ForegroundColor Green
Write-Host "The original AppData folder was NOT deleted."
Write-Host "Test the portable build, then optionally run CLEAN-OLD-HOST-DATA.ps1."
Write-Host ""
Read-Host "Press Enter to close" | Out-Null
