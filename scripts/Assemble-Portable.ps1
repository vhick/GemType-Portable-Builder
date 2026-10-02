param(
    [Parameter(Mandatory=$true)]
    [string]$SourceRoot,

    [Parameter(Mandatory=$true)]
    [string]$OutputRoot,

    [Parameter(Mandatory=$true)]
    [string]$KitRoot
)

$ErrorActionPreference = "Stop"

$SourceRoot = [IO.Path]::GetFullPath($SourceRoot)
$desktop = Join-Path $SourceRoot "desktop"
$dist = Join-Path $desktop "dist"

if (-not (Test-Path -LiteralPath $dist -PathType Container)) {
    throw "electron-builder dist folder was not found: $dist"
}

$exeCandidates = @(
    Get-ChildItem -LiteralPath $dist -Filter "*.exe" -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -notmatch "(?i)uninstall|setup" -and
        $_.DirectoryName -notmatch "(?i)unpacked"
    } |
    Sort-Object LastWriteTime -Descending
)

if ($exeCandidates.Count -eq 0) {
    throw "No portable Windows EXE was found in desktop\dist."
}

$exe = $exeCandidates[0]

if (Test-Path -LiteralPath $OutputRoot) {
    Remove-Item -LiteralPath $OutputRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputRoot "Data") -Force | Out-Null

Copy-Item -LiteralPath $exe.FullName `
    -Destination (Join-Path $OutputRoot "GemType-Portable.exe") `
    -Force

foreach ($name in @(
    "LAUNCH-GEMTYPE-PORTABLE.cmd",
    "INSTALL-PORTABLE-STARTUP.cmd",
    "REMOVE-PORTABLE-STARTUP.cmd",
    "VERIFY-PORTABLE.ps1",
    "MIGRATE-OFFICIAL-DATA.ps1",
    "CLEAN-OLD-HOST-DATA.ps1"
)) {
    Copy-Item -LiteralPath (Join-Path $KitRoot "portable\$name") `
        -Destination (Join-Path $OutputRoot $name) `
        -Force
}

$patchMarker = Join-Path $SourceRoot ".gemtype-true-portable-patch.json"

if (-not (Test-Path -LiteralPath $patchMarker -PathType Leaf)) {
    throw "Portable patch marker is missing."
}

Copy-Item -LiteralPath $patchMarker `
    -Destination (Join-Path $OutputRoot "TRUE-PORTABLE-PATCH.json") `
    -Force

$revision = (git -C $SourceRoot rev-parse HEAD).Trim()

[ordered]@{
    mode = "true-portable-electron"
    upstream_revision = $revision
    built_at = (Get-Date).ToString("o")
    executable = "GemType-Portable.exe"
    data_root = "./Data"
    settings_file = "./Data/UserData/settings.json"
    api_key_portable = $true
    api_key_encrypted = $false
    package_target = "electron-builder portable"
    installer_registry_entries = $false
    note = "GemType upstream stores the API key in plain settings.json. The portable fork relocates that same file beside the EXE."
} |
    ConvertTo-Json -Depth 6 |
    Set-Content -LiteralPath (Join-Path $OutputRoot "PORTABLE-BUILD.json") -Encoding UTF8

Set-Content -LiteralPath (Join-Path $OutputRoot "SOURCE-REVISION.txt") `
    -Encoding UTF8 `
    -Value @(
        "Source: synced GemType fork",
        "Upstream project: https://github.com/riponcm/GemType",
        "Revision: $revision",
        "Built: $(Get-Date)",
        "Target: electron-builder portable x64"
    )

foreach ($pair in @(
    @{ Source=(Join-Path $SourceRoot "LICENSE"); Destination="LICENSE-UPSTREAM.txt" },
    @{ Source=(Join-Path $SourceRoot "NOTICE"); Destination="NOTICE-UPSTREAM.txt" },
    @{ Source=(Join-Path $SourceRoot "TRADEMARK.md"); Destination="TRADEMARK-UPSTREAM.txt" }
)) {
    if (Test-Path -LiteralPath $pair.Source -PathType Leaf) {
        Copy-Item -LiteralPath $pair.Source `
            -Destination (Join-Path $OutputRoot $pair.Destination) `
            -Force
    }
}

Write-Host "Portable package assembled:" -ForegroundColor Green
Write-Host "  $OutputRoot"
