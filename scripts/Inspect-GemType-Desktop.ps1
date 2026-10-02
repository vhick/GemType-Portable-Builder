param(
    [Parameter(Mandatory=$true)]
    [string]$SourceRoot,

    [Parameter(Mandatory=$true)]
    [string]$OutputRoot
)

$ErrorActionPreference = "Stop"

$SourceRoot = [IO.Path]::GetFullPath($SourceRoot)
$DesktopRoot = Join-Path $SourceRoot "desktop"

if (-not (Test-Path -LiteralPath $DesktopRoot -PathType Container)) {
    throw "Expected GemType desktop folder was not found: $DesktopRoot"
}

if (Test-Path -LiteralPath $OutputRoot) {
    Remove-Item -LiteralPath $OutputRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

$revision = (git -C $SourceRoot rev-parse HEAD).Trim()

$report = Join-Path $OutputRoot "GemType-Desktop-Inspection.txt"
$sourceCopy = Join-Path $OutputRoot "Desktop-Source"
$rootCopy = Join-Path $OutputRoot "Repository-Metadata"

New-Item -ItemType Directory -Path $sourceCopy,$rootCopy -Force | Out-Null

# Copy the entire desktop source. This is intentionally source-only.
# Use Get-ChildItem -Force because -LiteralPath intentionally does NOT
# expand wildcard characters such as "*".
Get-ChildItem -LiteralPath $DesktopRoot -Force |
    Copy-Item `
        -Destination $sourceCopy `
        -Recurse `
        -Force

foreach ($relative in @(
    "README.md",
    "PRIVACY.md",
    "LICENSE",
    "NOTICE",
    "TRADEMARK.md"
)) {
    $source = Join-Path $SourceRoot $relative

    if (Test-Path -LiteralPath $source -PathType Leaf) {
        Copy-Item -LiteralPath $source -Destination (Join-Path $rootCopy $relative) -Force
    }
}

Set-Content -LiteralPath $report -Encoding UTF8 -Value @(
    "GEMTYPE DESKTOP PORTABILITY SOURCE INSPECTION",
    "Revision: $revision",
    "Generated: $(Get-Date)",
    "",
    "SOURCE CODE ONLY.",
    "This workflow does NOT read your API key, Windows registry, AppData, browser data, clipboard, or local GemType settings.",
    ""
)

function Add-Section {
    param([string]$Title)

    Add-Content -LiteralPath $report -Encoding UTF8 -Value @(
        "",
        ("=" * 78),
        $Title,
        ("=" * 78)
    )
}

Add-Section "DESKTOP FILE INVENTORY"

Get-ChildItem -LiteralPath $DesktopRoot -Recurse -File |
    Sort-Object FullName |
    ForEach-Object {
        $rel = $_.FullName.Substring($SourceRoot.Length).TrimStart('\')
        Add-Content -LiteralPath $report -Encoding UTF8 -Value $rel
    }

$packageJson = Join-Path $DesktopRoot "package.json"

Add-Section "DESKTOP PACKAGE.JSON SUMMARY"

if (Test-Path -LiteralPath $packageJson -PathType Leaf) {
    $package = Get-Content -LiteralPath $packageJson -Raw | ConvertFrom-Json

    foreach ($field in @("name","productName","version","description","main","author","license")) {
        if ($package.PSObject.Properties.Name -contains $field) {
            Add-Content -LiteralPath $report -Encoding UTF8 `
                -Value ("{0}: {1}" -f $field,[string]$package.$field)
        }
    }

    Add-Content -LiteralPath $report -Encoding UTF8 -Value ""
    Add-Content -LiteralPath $report -Encoding UTF8 -Value "scripts:"

    if ($package.scripts) {
        $package.scripts.PSObject.Properties |
            Sort-Object Name |
            ForEach-Object {
                Add-Content -LiteralPath $report -Encoding UTF8 `
                    -Value ("  {0}: {1}" -f $_.Name,[string]$_.Value)
            }
    }

    Add-Content -LiteralPath $report -Encoding UTF8 -Value ""
    Add-Content -LiteralPath $report -Encoding UTF8 -Value "dependencies:"

    if ($package.dependencies) {
        $package.dependencies.PSObject.Properties |
            Sort-Object Name |
            ForEach-Object {
                Add-Content -LiteralPath $report -Encoding UTF8 `
                    -Value ("  {0}: {1}" -f $_.Name,[string]$_.Value)
            }
    }

    Add-Content -LiteralPath $report -Encoding UTF8 -Value ""
    Add-Content -LiteralPath $report -Encoding UTF8 -Value "devDependencies:"

    if ($package.devDependencies) {
        $package.devDependencies.PSObject.Properties |
            Sort-Object Name |
            ForEach-Object {
                Add-Content -LiteralPath $report -Encoding UTF8 `
                    -Value ("  {0}: {1}" -f $_.Name,[string]$_.Value)
            }
    }

    if ($package.build) {
        Add-Content -LiteralPath $report -Encoding UTF8 -Value ""
        Add-Content -LiteralPath $report -Encoding UTF8 -Value "electron-builder build object:"
        Add-Content -LiteralPath $report -Encoding UTF8 `
            -Value ($package.build | ConvertTo-Json -Depth 20)
    }
}
else {
    Add-Content -LiteralPath $report -Encoding UTF8 `
        -Value "desktop/package.json was not present in this revision."
}

$groups = [ordered]@{
    "ELECTRON PATH / STORAGE" = @(
        "app.getPath",
        "app.setPath",
        "setAppLogsPath",
        "userData",
        "sessionData",
        "appData",
        "logs",
        "crashDumps",
        "cache",
        "localStorage",
        "sessionStorage",
        "indexedDB",
        "electron-store",
        "Store("
    )

    "FILES / SETTINGS" = @(
        "writeFile",
        "writeFileSync",
        "readFile",
        "readFileSync",
        "mkdir",
        "JSON.stringify",
        "JSON.parse",
        "settings",
        "config",
        "preferences"
    )

    "API KEY / SECRET STORAGE" = @(
        "apiKey",
        "api_key",
        "geminiKey",
        "secret",
        "safeStorage",
        "keytar",
        "credential",
        "password",
        "encrypt",
        "decrypt"
    )

    "WINDOWS STARTUP / REGISTRY" = @(
        "setLoginItemSettings",
        "getLoginItemSettings",
        "autoLaunch",
        "auto-launch",
        "startup",
        "registry",
        "winreg",
        "HKCU",
        "Run"
    )

    "UPDATER" = @(
        "autoUpdater",
        "electron-updater",
        "checkForUpdates",
        "downloadUpdate",
        "quitAndInstall"
    )

    "PACKAGING / PORTABLE TARGET" = @(
        "electron-builder",
        "portable",
        "nsis",
        "appId",
        "productName",
        "artifactName",
        "extraResources",
        "PORTABLE_EXECUTABLE_DIR",
        "PORTABLE_EXECUTABLE_FILE"
    )
}

$extensions = @(
    ".js",".cjs",".mjs",".json",".html",".ts",".tsx",".jsx",".yml",".yaml"
)

$files = @(
    Get-ChildItem -LiteralPath $DesktopRoot -Recurse -File |
    Where-Object { $_.Extension.ToLowerInvariant() -in $extensions }
)

foreach ($group in $groups.GetEnumerator()) {
    Add-Section $group.Key

    $anyHit = $false

    foreach ($file in $files) {
        $lines = Get-Content -LiteralPath $file.FullName -ErrorAction SilentlyContinue
        if ($null -eq $lines) { continue }

        for ($i=0; $i -lt $lines.Count; $i++) {
            $line = [string]$lines[$i]
            $hitTerm = $null

            foreach ($term in $group.Value) {
                if ($line.IndexOf($term,[StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $hitTerm = $term
                    break
                }
            }

            if (-not $hitTerm) { continue }

            $anyHit = $true
            $rel = $file.FullName.Substring($SourceRoot.Length).TrimStart('\')
            $from = [Math]::Max(0,$i-4)
            $to = [Math]::Min($lines.Count-1,$i+8)

            Add-Content -LiteralPath $report -Encoding UTF8 `
                -Value ("--- {0} | match: {1} | line {2} ---" -f $rel,$hitTerm,($i+1))

            for ($j=$from; $j -le $to; $j++) {
                Add-Content -LiteralPath $report -Encoding UTF8 `
                    -Value ("{0,5}: {1}" -f ($j+1),$lines[$j])
            }

            Add-Content -LiteralPath $report -Encoding UTF8 -Value ""
        }
    }

    if (-not $anyHit) {
        Add-Content -LiteralPath $report -Encoding UTF8 -Value "No matches found."
    }
}

Add-Section "WHAT TO SEND BACK"

Add-Content -LiteralPath $report -Encoding UTF8 -Value @(
    "Upload the complete GemType-Desktop-Inspection-<commit> artifact to ChatGPT.",
    "",
    "The artifact contains upstream source only.",
    "It does not contain your Gemini API key or any data from your PC."
)

Set-Content -LiteralPath (Join-Path $OutputRoot "UPSTREAM-REVISION.txt") `
    -Encoding UTF8 `
    -Value $revision

Write-Host ""
Write-Host "GemType desktop inspection complete." -ForegroundColor Green
Write-Host "Output:"
Write-Host "  $OutputRoot"
