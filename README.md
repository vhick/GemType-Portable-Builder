# GemType Portable Builder — Inspection Edition

This temporary builder does **not** compile GemType yet.

Its only job is to inspect the exact current desktop source from your clean `GemType` fork so the true-portable patch can be written safely.

## Why inspect first?

GemType Desktop is an Electron app. Electron normally stores application configuration under `userData`, and browser/session storage under `sessionData`.

A true portable build can normally redirect those paths beside the executable, but the API key and settings must first be checked in the actual GemType desktop source.

The inspection collects source code only.

It does **not** read:
- your Gemini API key;
- your AppData;
- Windows Credential Manager;
- your registry;
- your clipboard;
- any local GemType data.

## Repository name

Create a normal repository named exactly:

`GemType-Portable-Builder`

## Source fork

Create a clean fork named exactly:

`GemType`

from:

`riponcm/GemType`

Your existing Universal Fork Sync will already keep that fork synchronized because it discovers all of your forks.

Do not put custom portable patches in the clean `GemType` fork.

## First action

Run the GitHub workflow manually and download:

`GemType-Desktop-Inspection-<commit>`

Then upload that artifact to ChatGPT.

After that inspection, replace this temporary repository content with the final true-portable builder.
