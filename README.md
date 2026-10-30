# CalmWorks

**CalmWorks** is a Roblox educational business simulation for practicing thoughtful responses to everyday disagreements. Created for the **2026 Congressional App Challenge**, it combines realistic customer situations, feedback, adaptive practice, and a growing in-game business.

![A CalmWorks online customer consultation](assets/CalmWorks_Certification_Gameplay.jpg)

## Try it

- **Play the official published experience:** https://www.roblox.com/games/137721325206604/CalmWorks
- **Obtain an editable copy from Roblox:** CalmWorks is **uncopylocked**. Open the [official Roblox experience page](https://www.roblox.com/games/137721325206604/CalmWorks), sign in, open the **⋯** menu, and select **Edit in Studio** where available. In Studio, use **File → Save to File** to save your own local copy. The live Roblox version may differ from the snapshot in this repository.
- **Watch the 2026 CAC demonstration:** https://www.youtube.com/watch?v=z6danf7mGwI

## Features

- **Interactive conflict-resolution practice:** Respond to realistic situations using three-choice questions or written answers, with constructive feedback.
- **Curated cases:** 100 scenarios across 10 categories, including 40 linked multistage conversations (140 dialogue stages total).
- **Adaptive recommendations:** First-attempt results from a rolling window of up to 50 answers guide weighted category practice, increasing attention to weaker areas while preserving variety.
- **Business simulation:** Customers with distinct personalities, NPC navigation and queues, employees and managers, workplace concerns, private guidance sessions, online consultations, and **four business expansions**. The fifth and final star is awarded after completing the final expansion's requirements.
- **Progress tracking:** Category accuracy, a radar visualization, historical snapshots, and saved business progression.
- **AI-supported interactions:** Roblox's native `TextGenerator` is used for candidate scenarios and support responses. Structural checks, independent review, filtering, and curated fallbacks help maintain consistent behavior when generation is unavailable or unsuitable.

CalmWorks is an educational practice experience, **not** clinical therapy, a diagnostic assessment, or proof of improved real-world behavior.

## Technology

- **Roblox Studio** and **Luau**
- Server-authoritative gameplay with client-side user interfaces
- Roblox `PathfindingService`, `DataStoreService`, and native `TextGenerator`
- Modular scenario, adaptive-practice, employee, NPC, dashboard, and save systems
- Input validation, asynchronous processing, and save-data compatibility handling

## Open and run in Roblox Studio

1. Install **Roblox Studio** and sign in with a Roblox account.
2. Obtain an editable copy using one of two methods:
   - **From this repository:** Download the repository and open `game/CalmWorks.rbxl` with **File → Open from File**. The `src/` directory is a readable mirror of the embedded Luau code, not a standalone playable project.
   - **From Roblox directly:** Visit the [official, uncopylocked experience](https://www.roblox.com/games/137721325206604/CalmWorks), choose **⋯ → Edit in Studio** if shown, then select **File → Save to File** to save a local copy.
3. Press **Play** in Roblox Studio to test the experience. For the currently published version, play the [official Roblox game](https://www.roblox.com/games/137721325206604/CalmWorks).

### Studio API access and data saving

**Ordinary playtesting in Studio does not require persistent DataStore access.** By default, `Config.SaveInStudio = false` in `ReplicatedStorage → CalmWorksShared → Config`, so Studio sessions do not load or save player DataStore progress.

To **test persistent saving and loading in Studio**:

1. Publish the downloaded place as a **separate test experience you own**, rather than testing writes against the original live game's DataStores.
2. In Roblox Studio, open **Experience Settings / Game Settings → Security** and enable **Studio Access to API Services**. Save the change.
3. In the `Config` ModuleScript at `ReplicatedStorage → CalmWorksShared → Config`, temporarily set `Config.SaveInStudio = true`.
4. Start a new play session and verify saving/loading. Return `Config.SaveInStudio` to `false` when testing is finished.

**External HTTP / remote server requests:** The exported scripts use `HttpService` for operations such as JSON encoding, decoding, and unique identifiers, but do not call outbound `HttpService:GetAsync`, `PostAsync`, or `RequestAsync` methods. Therefore, **Allow HTTP Requests is not required** for this exported version. Enable it only if a later feature actually makes external HTTP requests.

**Native Roblox AI:** AI generation uses Roblox `TextGenerator`, not an external HTTP endpoint. Availability and permissions may depend on the Roblox account and experience. Curated scenarios provide fallbacks when scenario generation is unavailable. Some Roblox-hosted assets, features, or permissions may not transfer automatically to another account.

## Exported source code

The repository contains the complete binary Roblox Studio place at **`game/CalmWorks.rbxl`** and **115 extracted Luau source files** under `src/`:

| Script type | Count |
| --- | ---: |
| ModuleScripts | 79 |
| Scripts | 19 |
| LocalScripts | 17 |
| **Total** | **115** |

The latest supplied place export contains **7,255 serialized Roblox instances** and approximately **36,073 source lines**, including blank lines and any Toolbox or backup scripts. The `src/` tree preserves original instance paths for independent source review. The `.rbxl` file is the actual playable Studio place; the extracted source is an inspection-friendly mirror.

**Backup files are included intentionally.** The latest export contains backup scripts in `ServerStorage`, including folders named `ReliabilityFixBackup_20261030_012510` and `MoraleSchedulingBackup_20261030_022532`, as well as an earlier scenario-library backup. They are included in the 115-file total for fidelity and should **not** all be interpreted as active runtime modules.

`SOURCE_INVENTORY.json` records the extracted scripts, their class types, paths, byte counts, source line counts, and SHA-256 hashes, along with the hash of the source place file. These counts verify what was extracted from this specific snapshot; they do **not** independently confirm that every gameplay feature works in a fresh Studio environment.

## Repository layout

```text
CalmWorks/
├── README.md
├── LICENSE
├── EXPORT_NOTES.md
├── SOURCE_INVENTORY.json
├── game/
│   └── CalmWorks.rbxl
├── src/
│   ├── ReplicatedFirst/
│   ├── ReplicatedStorage/
│   ├── ServerScriptService/
│   ├── ServerStorage/
│   │   ├── ReliabilityFixBackup_20261030_012510/
│   │   └── MoraleSchedulingBackup_20261030_022532/
│   ├── StarterGui/
│   ├── StarterPlayer/
│   └── Workspace/
└── assets/
    ├── CalmWorks_Certification_Gameplay.jpg
    ├── CalmWorks_Certification_Interaction.jpg
    ├── CalmWorks_Certification_Progress.jpg
    ├── VersionHistory_Initial_August.png
    ├── VersionHistory_September.png
    ├── VersionHistory_October.png
    └── VersionHistory_Final_October.png
```

**Review note:** The repository is an exported snapshot of a Roblox Studio place. Reviewers should open `game/CalmWorks.rbxl` in Studio and independently test the experience. Native services, asset access, and permissions may vary between Roblox accounts and experiences.

## Engineering decisions

CalmWorks validates player answers, purchases, rewards, and progression through authoritative server systems rather than trusting client requests. Scenario generation occurs asynchronously; malformed options, inconsistent answer identifiers, or unsuitable results are rejected in favor of curated fallbacks. The game uses modular systems for adaptive practice, navigation, staffing, progression, and persistence. Save operations include input validation and compatibility handling for older data versions.

## Development and AI assistance

The creator designed the original concept, educational scenarios, business progression, adaptive-practice requirements, and user experience, and wrote, integrated, modified, and tested the game's Luau systems. OpenAI Codex assisted with portions of programming, debugging, refactoring, and GUI foundations; ChatGPT assisted with dialogue; and Gemini Flash was used for artwork. Roblox `TextGenerator` is a native existing service, **not** a newly trained machine-learning model created for this project.

## Development and version history

CalmWorks was developed primarily in Roblox Studio for the 2026 Congressional App Challenge **before this GitHub repository was created**. Consequently, GitHub commits document the later process of exporting, organizing, publishing, and maintaining the open-source repository rather than the complete original development timeline.

Roblox maintains a separate saved/published version history for the original experience. The screenshots below show that Roblox's Creator Dashboard recorded **530 versions as of October 28, 2026**, with the earliest versions dated **August 4, 2026**. The complete Roblox history remains available to the experience creator through Roblox Studio or Creator Dashboard.

### Historical development evidence

- [Initial development — August 2026](assets/VersionHistory_Initial_August.png)
- [Intermediate development — August–September 2026](assets/VersionHistory_September.png)
- [Continued development — October 2026](assets/VersionHistory_October.png)
- [Later development — October 2026](assets/VersionHistory_Final_October.png)

The `game/CalmWorks.rbxl` file is the latest exported place snapshot in this repository, while `src/` provides a matching source-code mirror. Historical Roblox saves and GitHub publication commits represent **different** development records; no earlier Git commits have been fabricated or backdated.

## Future work

Potential improvements include structured user testing, standardized evaluation separate from adaptive practice, more branching conversations, additional accessibility work, and automated tests.

## License and asset attribution

CalmWorks was developed for the 2026 Congressional App Challenge using Roblox Studio and Luau. Its original programming, gameplay systems, educational scenarios, and user interfaces are accompanied by selected publicly available assets from Roblox Studio's Toolbox / Creator Store.

### Open-source license

The original source code and other original materials owned by the developer are released under the **MIT License**. See [LICENSE](LICENSE) for the complete terms. This license permits use, modification, and redistribution of the covered original software subject to its license conditions.

### Third-party Roblox assets

Some models, meshes, textures, audio, scripts, and other assets may come from Roblox Studio's public Toolbox or Creator Store. These assets remain subject to their creators' rights and applicable Roblox terms. **They are not independently relicensed under CalmWorks' MIT License.** Public availability in the Toolbox does not necessarily authorize unrestricted redistribution outside Roblox. Asset-specific terms and attribution requirements must still be respected.

### Development and attribution

CalmWorks' concept, educational design, gameplay integration, and overall project development were directed by the developer. AI-assisted tools, including OpenAI Codex and ChatGPT, were used during aspects of programming, debugging, and content development, with Gemini Flash used for artwork. Certain runtime AI features are powered by Roblox's existing services and APIs.

The original materials are available for educational exploration, source inspection, and further development under the applicable licenses and permissions.