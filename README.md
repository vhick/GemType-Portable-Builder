# GemType True-Portable Builder

This builder creates a Windows **electron-builder portable target** from your clean synced `GemType` fork.

The source patch redirects:

- Electron `userData` → `.\Data\UserData`
- Electron `sessionData` → `.\Data\SessionData`
- logs → `.\Data\Logs`
- crash dumps → `.\Data\CrashDumps`

The inspected upstream desktop app stores its API key, model and language together in `settings.json` under `userData`. Therefore the API key becomes portable automatically at:

`.\Data\UserData\settings.json`

It remains plain JSON, matching upstream behavior.

## Normal build

Actions → Build GemType Portable → Run workflow → `portable-data`

## Future-source diagnostics

If a future upstream update breaks the patch, use:

`inspect-source`

and send the artifact to ChatGPT.

## Trademark

The upstream repository states that the GemType name/logo are trademarks and asks redistributed forks to use a distinct name/icon. This builder is intended for personal/private use. Rebrand before public redistribution.
