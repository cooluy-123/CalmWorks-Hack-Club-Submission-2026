# CalmWorks

**CalmWorks** is a Roblox educational business simulation for practicing thoughtful responses to everyday disagreements. Created for the **2026 Congressional App Challenge**, it combines realistic customer situations, feedback, adaptive practice, and a growing in-game business.

![A CalmWorks online customer consultation](assets/CalmWorks_Certification_Gameplay.jpg)

## Try it

- **Play the official published experience:** https://www.roblox.com/games/137721325206604/CalmWorks
- **Download an editable copy from Roblox:** CalmWorks has been made **uncopylocked**. Open the [official Roblox experience page](https://www.roblox.com/games/137721325206604/CalmWorks), sign in, select the **⋯** menu near the experience title, and choose **Edit in Studio**. In Roblox Studio, use **File → Save to File** (or **Save As**) to keep a local copy. This copies the publicly available Roblox place; it may be a newer version than the fixed export committed to this repository.
- **Watch the 2026 CAC demonstration:** https://www.youtube.com/watch?v=z6danf7mGwI

## Features

- **Interactive practice:** Three-choice or written responses with constructive, scenario-specific feedback.
- **Curated cases:** 100 scenarios across 10 categories, including 40 linked multistage conversations (140 dialogue stages total).
- **Adaptive recommendations:** First-attempt results from a rolling window of up to 50 responses inform category practice. Selection increases attention to weaker areas while preserving variety.
- **Business simulation:** Employees, managers, customer personalities, workplace concerns, private guidance sessions, online consultations, NPC routing, and four expansions.
- **Progress:** Category statistics, a radar visualization, historical snapshots, and saved business progression.
- **AI-backed interactions:** Roblox's existing TextGenerator generates candidate scenarios and support responses; structured checks, independent review, filtering, and curated fallbacks reduce unsuitable or inconsistent results.

## Technology

- Roblox Studio and **Luau**
- Server-authoritative gameplay, with clients handling UI and user input
- Roblox PathfindingService, DataStore APIs, and TextGenerator
- Modular scenario, adaptive-practice, NPC, employee, dashboard, and save systems

## Open and run in Roblox Studio

1. Install **Roblox Studio** and sign in with your Roblox account.
2. Obtain an editable copy in either of these ways:
   - **From GitHub:** Download this repository and open the complete place export at `game/CalmWorks.rbxl` using **File → Open from File**. The `src/` folder contains a separate, readable mirror of the Luau code.
   - **Directly from Roblox:** Visit the [official, uncopylocked CalmWorks experience](https://www.roblox.com/games/137721325206604/CalmWorks), select **⋯ → Edit in Studio**, then use **File → Save to File** to download your own local copy.
3. Press **Play** in Studio to test the game. Playing the [published experience](https://www.roblox.com/games/137721325206604/CalmWorks) is the easiest way to try its currently live version.

### Studio API access and data saving

**Ordinary Studio playtesting does not require enabling persistent saving.** CalmWorks deliberately defaults to `Config.SaveInStudio = false` in `ReplicatedStorage/CalmWorksShared/Config`, so Studio sessions do not read or write player DataStores.

To **test persistent saved progress in Studio**:

1. **Publish the downloaded place as a separate test experience you own.** Do not experiment with your original live experience's production save data.
2. In Roblox Studio, open **File → Experience Settings → Security** (sometimes labeled **Game Settings → Security**) and enable **Enable Studio Access to API Services**. Save the setting.
3. In the **Config ModuleScript** at `ReplicatedStorage → CalmWorksShared → Config`, temporarily set `Config.SaveInStudio = true`.
4. Restart the Studio play session and test saving/loading. Restore `Config.SaveInStudio = false` when finished testing.

**Allow HTTP Requests / remote server requests:** This exported version uses `HttpService` for JSON encoding/decoding and generating identifiers, **not for outbound HTTP requests** such as `GetAsync`, `PostAsync`, or `RequestAsync`. Therefore, enabling **Allow HTTP Requests** is **not a prerequisite** for the included gameplay. Turn it on only if you add a feature that genuinely makes external HTTP requests.

**AI services:** The game uses Roblox's native `TextGenerator` objects. AI-powered responses may require Roblox-side availability, eligibility, and permissions for the testing experience; enabling HTTP requests does not itself grant those permissions. The game includes curated scenario fallbacks when AI generation is unavailable.

Some Roblox-hosted assets or services may not transfer automatically to another account, and some assets may require separate permissions. Review the rights to imported assets before redistributing them.

## Exported source code

This repository includes the original binary Studio place file (`game/CalmWorks.rbxl`) and **100 separately extracted Luau files** in `src/` (68 ModuleScripts, 16 Scripts, 16 LocalScripts). The `src/` files are a reviewer-friendly mirror of the embedded scripts, preserving their original Studio parent paths; **the `.rbxl` file is the runnable place**, not the `src/` folder by itself. A machine-generated `SOURCE_INVENTORY.json` lists individual paths, types, source sizes, and hashes.

The export currently contains **6,798 serialized Roblox instances**. Script source line count is approximately **26,145** (including empty lines and any imported/third-party scripts). These counts document this particular place export; they do not independently verify behavior in a separate Studio session.


## Repository layout

```text
CalmWorks/
├── README.md
├── LICENSE
├── EXPORT_NOTES.md
├── SOURCE_INVENTORY.json
│
├── game/
│   └── CalmWorks.rbxl
│
├── src/
│   ├── ReplicatedFirst/
│   ├── ReplicatedStorage/
│   ├── ServerScriptService/
│   ├── ServerStorage/
│   ├── StarterGui/
│   ├── StarterPlayer/
│   └── Workspace/
│
└── assets/
    ├── CalmWorks_Certification_Gameplay.jpg
    ├── CalmWorks_Certification_Interaction.jpg
    ├── CalmWorks_Certification_Progress.jpg
    ├── VersionHistory_Initial_August.png
    ├── VersionHistory_September.png
    ├── VersionHistory_October.png
    └── VersionHistory_Final_October.png
```

**Review note:** This repository mirrors a locally saved Studio file. The publisher should open `game/CalmWorks.rbxl` in Roblox Studio and verify the experience functions before submitting it for independent review; Roblox-hosted assets, permissions, and API features may differ by account.

## Engineering decisions

The game separates player input from authoritative server checks for answers, purchases, rewards, and progression. Scenario generation is prepared in the background; malformed choices or mismatched answer identifiers are rejected, and an approved preset scenario is used when no suitable generated content is available within the brief player-facing loading window. Save operations include validation and compatibility handling for changes between versions.

## Development and AI assistance

The creator designed the original concept, educational scenarios, progression mechanics, adaptive-practice requirements, and overall user experience, and wrote, integrated, modified, and tested Luau gameplay systems. OpenAI Codex assisted with aspects of code development, debugging, refactoring, and GUI foundations; ChatGPT assisted with dialogue, and Gemini Flash was used for artwork. Roblox's TextGenerator is an existing AI service, **not** a new model trained for this project.

## Development and Version History

CalmWorks was originally developed in Roblox Studio for the 2026 Congressional App Challenge. Most of the project's development occurred directly within Roblox Studio before this GitHub repository was created.

As a result, the GitHub commit history primarily documents the process of exporting, organizing, documenting, and publishing the completed project as open source, rather than its entire development timeline.

Roblox maintains a separate version history of saved and published versions of the original CalmWorks experience. These earlier versions can be accessed by the creator through Roblox Studio (**Window → Version History**) or the Roblox Creator Dashboard.

The file `game/CalmWorks.rbxl` represents an exported snapshot of the project, while `src/` provides the extracted Luau scripts for independent code inspection.

The original Roblox development history is retained separately from this repository and can be provided as supporting evidence of the project's development process upon request.

### Historical Development Evidence

CalmWorks was originally developed in Roblox Studio before
this GitHub repository was created.

Roblox's Creator Dashboard records 530 saved versions,
dating from August 4 to October 28, 2026.

These screenshots document the project's development timeline:

- [Initial development — August 2026](assets/VersionHistory_Initial_August.png)
- [Intermediate development — August–September 2026](assets/VersionHistory_September.png)
- [Continued development — October 2026](assets/VersionHistory_October.png)
- [Final development — October 2026](assets/VersionHistory_Final_October.png)

The complete version history remains accessible through the
original CalmWorks experience in Roblox Creator Dashboard.

GitHub commits document the later process of exporting,
organizing, and publishing CalmWorks as open-source software.

## Future work

Potential improvements include structured playtesting, a standardized assessment separate from adaptive practice, more branching conversations, accessibility refinements, and further automated tests.

## License and Asset Attribution

CalmWorks is an educational Roblox experience developed for the 2026 Congressional App Challenge using Roblox Studio and Luau.

The project consists of original programming, gameplay systems, educational scenarios, user interfaces, and other content developed by the creator, alongside selected publicly available assets obtained through Roblox Studio's Toolbox and Creator Store.

### Open-Source License

The original source code and other original materials owned by the developer are released under the MIT License. See the [LICENSE](LICENSE) file for the full terms.

The MIT License permits others to use, modify, distribute, and build upon the covered original software, provided that the required copyright and license notices are preserved.

### Third-Party Roblox Assets

Some models, meshes, textures, audio, scripts, and other assets used in CalmWorks may originate from Roblox Studio's public Toolbox or Creator Store.

These third-party assets remain the property of their respective creators and are subject to their original licensing conditions and applicable Roblox terms. They are not independently relicensed under CalmWorks' MIT License.

Public availability through Roblox Studio does not necessarily grant permission for unrestricted redistribution outside the Roblox platform. Any third-party assets included in this repository must be used and redistributed in accordance with their applicable permissions.

### Development and Attribution

CalmWorks' concept, educational design, gameplay integration, and project development were directed by Vrishank Yarra. AI-assisted tools, including OpenAI Codex and ChatGPT, were used during aspects of programming, debugging, and content development. Existing Roblox services and APIs are used for selected AI-powered features.

The project is available for educational exploration, source-code inspection, and further development in accordance with the applicable licenses and permissions.
