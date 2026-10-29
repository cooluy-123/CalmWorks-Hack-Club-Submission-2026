# Export notes and upload instructions

- **Original input:** `CalmWorks1.rbxl` (uploaded by project creator).
- **Included complete place:** `game/CalmWorks.rbxl`. This is the original binary place; do not change `.rbxl` to `.rbxlx` by renaming it.
- **Extracted source:** `src/` contains every of the 100 instances with a `Source` property found in that place export: 68 ModuleScripts, 16 Scripts, 16 LocalScripts.
- **Method:** read Roblox binary `INST`, `PROP`, and `PRNT` chunks, decode ZSTD/LZ4 chunks, preserve literal `Source` bytes, and reconstruct parent paths and names. Duplicate object paths have a unique referent suffix. The extracted scripts are documentation/source browsing files; the full place is what you open in Roblox Studio.
- **Inventory:** `SOURCE_INVENTORY.json` lists each extracted script's path, type, byte size, line count, and SHA-256, and the SHA-256 of the input place.
- **Testing:** This extraction confirms the place file was structurally parsable, **not** that every feature will work in a fresh Roblox Studio environment. Open the actual place from this repository and test before certification submission.
- **Third-party/IP:** You must review rights to re-license or redistribute included Roblox assets and scripts; for example the `EpicCowCar` model has its own code. This package does not verify ownership of those items.
- **Security:** An automated check did not detect obvious long-format API tokens or URLs in script source; this is **not** a comprehensive security or personal-data audit.
- **History:** New Git commits accurately document the repository work from the time committed. Do not backdate or fabricate project history; include genuine older work evidence if available.

## To publish

1. Unzip this archive into a normal folder on your computer (do **not** upload the zip itself as a GitHub source repository).
2. Read and review this README and license, inspect imported asset rights, and run `game/CalmWorks.rbxl` in Roblox Studio.
3. Open your GitHub repository and choose **Add file > Upload files**, then drag in the contents of the extracted project folder. (The `.rbxl` file is under GitHub's standard web upload size limit.)
4. Add and commit real changes in clear steps; if you're adding everything together, use `Add Roblox place export and extracted Luau sources`.
5. Check public repo in a signed-out browser window and enter its URL in the certificate application.
