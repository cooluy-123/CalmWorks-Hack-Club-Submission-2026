# Export notes and upload instructions

- **Original input:** Latest creator-provided `CalmWorks.rbxl` snapshot (October 2026).
- **Included complete place:** `game/CalmWorks.rbxl`. This is the original binary place; do not change `.rbxl` to `.rbxlx` by renaming it.
- **Extracted source:** `src/` contains all 115 script instances with a `Source` property found in this place export: 79 ModuleScripts, 19 Scripts, and 17 LocalScripts (including retained backup scripts).
- **Method:** read Roblox binary `INST`, `PROP`, and `PRNT` chunks, decode ZSTD/LZ4 chunks, preserve literal `Source` bytes, and reconstruct parent paths and names. Duplicate object paths have a unique referent suffix. The extracted scripts are documentation/source browsing files; the full place is what you open in Roblox Studio.
- **Inventory:** `SOURCE_INVENTORY.json` lists each extracted script's path, type, byte size, line count, and SHA-256, and the SHA-256 of the input place.
- **Testing:** This extraction confirms the place file was structurally parsable, **not** that every feature will work in a fresh Roblox Studio environment. Open the actual place from this repository and test before certification submission.
- **Third-party/IP:** You must review rights to re-license or redistribute included Roblox assets and scripts; for example the `EpicCowCar` model has its own code. This package does not verify ownership of those items.
- **Security:** An automated check did not detect obvious long-format API tokens or URLs in script source; this is **not** a comprehensive security or personal-data audit.
- **History:** New Git commits accurately document the repository work from the time committed. Do not backdate or fabricate project history; include genuine older work evidence if available.

## Obtaining and running CalmWorks

- **Download the official, uncopylocked Roblox version:** Open https://www.roblox.com/games/137721325206604/CalmWorks while signed in, use the experience page's **⋯ → Edit in Studio** option, and save a local copy from Roblox Studio using **File → Save to File**. The official live version may be newer than the fixed snapshot included in this GitHub repository.
- **Run the GitHub export:** Download `game/CalmWorks.rbxl`, then open it using **File → Open from File** in Roblox Studio.
- **Studio DataStore testing (optional):** To test persistent player progress, first publish a separate test experience you own. In Studio's **Experience Settings / Game Settings → Security**, enable **Studio Access to API Services**, then set `Config.SaveInStudio = true` in `ReplicatedStorage/CalmWorksShared/Config`. This is not necessary for ordinary Studio gameplay; keep it `false` outside dedicated save tests.
- **External HTTP requests:** The exported Luau source uses `HttpService` for JSON and GUID operations, but it does not call outbound HTTP request methods; **Allow HTTP Requests** is not required for this version of CalmWorks. Roblox `TextGenerator` availability/permissions are separate from this setting; curated scenario fallbacks are included.
- **Limitations:** Some Roblox-hosted assets, permissions, live save data, and native AI capabilities may not transfer to another account.

## Updating the repository

The playable place, its extracted scripts, and `SOURCE_INVENTORY.json` must be updated together when the Studio export changes. The full place contains 7,255 serialized instances in this snapshot. Earlier GitHub history reflects open-source publication and later maintenance, not the original Roblox Studio development timeline.

## To publish

1. Download the repository or a source archive into a normal folder on your computer (do **not** replace the public source repository with a ZIP alone).
2. Read and review `README.md` and `LICENSE`, inspect imported asset rights, and run `game/CalmWorks.rbxl` in Roblox Studio.
3. When refreshing an export, replace `game/CalmWorks.rbxl`, its matching files under `src/`, and `SOURCE_INVENTORY.json` in the GitHub repository. Check that the source inventory matches the new binary.
4. Commit authentic changes with a description of the new export or documentation. Do not create or backdate commits to simulate earlier work.
5. Check public repo in a signed-out browser window and enter its URL in the certificate application.
