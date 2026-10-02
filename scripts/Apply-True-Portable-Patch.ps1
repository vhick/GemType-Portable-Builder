param(
    [Parameter(Mandatory=$true)]
    [string]$SourceRoot
)

$ErrorActionPreference = "Stop"

$SourceRoot = [IO.Path]::GetFullPath($SourceRoot)
$mainFile = Join-Path $SourceRoot "desktop\main.js"

if (-not (Test-Path -LiteralPath $mainFile -PathType Leaf)) {
    throw "Expected desktop\main.js was not found."
}

$text = Get-Content -LiteralPath $mainFile -Raw

$marker = "// GEMTYPE_PORTABLE_PATHS_V1"

if ($text.Contains($marker)) {
    Write-Host "GemType portable path patch already present." -ForegroundColor DarkGray
}
else {
    $anchor = @'
const MATILY_URL = 'https://matily.org';

// ---------------------------------------------------------------------------
// Settings (plain JSON in userData)
'@

    if (-not $text.Contains($anchor)) {
        throw "GemType main.js no longer matches the inspected source. Failing closed so a non-portable build is not produced."
    }

    $portable = @'
const MATILY_URL = 'https://matily.org';

// GEMTYPE_PORTABLE_PATHS_V1
// electron-builder's Windows portable target exposes PORTABLE_EXECUTABLE_DIR.
// The packaged Electron app itself runs from a temporary extraction directory,
// so process.execPath alone is not enough to locate the original portable EXE.
const portableRoot =
  process.env.PORTABLE_EXECUTABLE_DIR
    ? path.resolve(process.env.PORTABLE_EXECUTABLE_DIR)
    : path.dirname(process.execPath);

const portableDataRoot = path.join(portableRoot, 'Data');
const portableUserData = path.join(portableDataRoot, 'UserData');
const portableSessionData = path.join(portableDataRoot, 'SessionData');
const portableLogs = path.join(portableDataRoot, 'Logs');
const portableCrashDumps = path.join(portableDataRoot, 'CrashDumps');

[
  portableDataRoot,
  portableUserData,
  portableSessionData,
  portableLogs,
  portableCrashDumps,
].forEach((dir) => fs.mkdirSync(dir, { recursive: true }));

// These overrides must happen before Electron's ready event. This keeps
// GemType settings, Chromium/session storage, logs and crash data beside the
// portable executable instead of under Windows AppData.
app.setPath('userData', portableUserData);
app.setPath('sessionData', portableSessionData);
app.setPath('logs', portableLogs);
app.setPath('crashDumps', portableCrashDumps);

// ---------------------------------------------------------------------------
// Settings (plain JSON in userData)
'@

    $text = $text.Replace($anchor,$portable)
    Set-Content -LiteralPath $mainFile -Value $text -Encoding UTF8
    Write-Host "Applied GemType true-portable path patch." -ForegroundColor Green
}

# Record patch metadata for the assembled artifact.
$revision = (git -C $SourceRoot rev-parse HEAD).Trim()

[ordered]@{
    patch = "GemType true-portable"
    patch_version = "1.0"
    upstream_revision = $revision
    applied_at = (Get-Date).ToString("o")
    portable_root_source = "PORTABLE_EXECUTABLE_DIR"
    data_root = "./Data"
    settings = "./Data/UserData/settings.json"
    session_data = "./Data/SessionData"
    logs = "./Data/Logs"
    crash_dumps = "./Data/CrashDumps"
    api_key_storage = "plain JSON inside settings.json (same upstream storage format, relocated)"
    windows_installer = $false
    windows_portable_target = $true
} |
    ConvertTo-Json -Depth 6 |
    Set-Content -LiteralPath (Join-Path $SourceRoot ".gemtype-true-portable-patch.json") -Encoding UTF8
