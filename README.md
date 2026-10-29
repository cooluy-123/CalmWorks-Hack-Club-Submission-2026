# CalmWorks

**CalmWorks** is a Roblox educational business simulation for practicing thoughtful responses to everyday disagreements. Created for the **2026 Congressional App Challenge**, it combines realistic customer situations, feedback, adaptive practice, and a growing in-game business.

![A CalmWorks online customer consultation](assets/CalmWorks_Certification_Gameplay.jpg)

## Try it

- **Play the published experience:** https://www.roblox.com/games/137721325206604/CalmWorks
- **Watch the 2026 CAC demonstration:** https://www.youtube.com/watch?v=z6danf7mGwI

## Features

- **Interactive practice:** Three-choice or written responses with constructive, scenario-specific feedback.
- **Curated cases:** 100 scenarios across 10 categories, including 40 linked multistage conversations (140 dialogue stages total).
- **Adaptive recommendations:** First-attempt results from a rolling window of up to 50 responses inform category practice. Selection increases attention to weaker areas while preserving variety.
- **Business simulation:** Employees, managers, customer personalities, workplace concerns, private guidance sessions, online consultations, NPC routing, and four expansions.
- **Progress:** Category statistics, a radar visualization, historical snapshots, and saved business progression.
- **AI-backed interactions:** Roblox's existing TextGenerator generates candidate scenarios and support responses; structured checks, independent review, filtering, and curated fallbacks reduce unsuitable or inconsistent results.

CalmWorks is an educational practice experience, **not** clinical assessment, therapy, or evidence of improved real-world behavior.

## Technology

- Roblox Studio and **Luau**
- Server-authoritative gameplay, with clients handling UI and user input
- Roblox PathfindingService, DataStore APIs, and TextGenerator
- Modular scenario, adaptive-practice, NPC, employee, dashboard, and save systems

## Open and run in Roblox Studio

1. Install **Roblox Studio** and sign in with a Roblox account.
2. Download this repository, including the full Studio place file at `game/CalmWorks.rbxlx` and the readable Luau source under `src/`.
3. In Roblox Studio, choose **File → Open from File** and open `game/CalmWorks.rbxlx`.
4. Press **Play** to test the experience. The published Roblox link above is the easiest way to experience the live game.
5. For a separate test copy with live DataStore persistence, publish to an experience **you own** and configure any required Studio API access. Roblox TextGenerator availability and permissions may depend on your account and experience configuration. Preset scenarios provide a fallback when generation is unavailable.

Some Roblox-hosted assets or services may not transfer automatically to another account. See in-repository asset notes for third-party asset permissions if included.

## Repository layout

```text
CalmWorks/
├── README.md
├── LICENSE
├── game/
│   └── CalmWorks.rbxlx           # Full Roblox Studio place export
├── src/                        # Readable Luau scripts / modules
└── assets/
    ├── CalmWorks_Certification_Gameplay.jpg
    ├── CalmWorks_Certification_Interaction.jpg
    └── CalmWorks_Certification_Progress.jpg
```

**Repository owner setup:** Make sure all listed files actually exist and that source exports match the playable version before submitting for review. If the layout differs, update this section to match. Do not submit this README in place of the project's actual code and place file.

## Engineering decisions

The game separates player input from authoritative server checks for answers, purchases, rewards, and progression. Scenario generation is prepared in the background; malformed choices or mismatched answer identifiers are rejected, and an approved preset scenario is used when no suitable generated content is available within the brief player-facing loading window. Save operations include validation and compatibility handling for changes between versions.

## Development and AI assistance

The creator designed the original concept, educational scenarios, progression mechanics, adaptive-practice requirements, and overall user experience, and wrote, integrated, modified, and tested Luau gameplay systems. OpenAI Codex assisted with aspects of code development, debugging, refactoring, and GUI foundations; ChatGPT assisted with dialogue, and Gemini Flash was used for artwork. Roblox's TextGenerator is an existing AI service, **not** a new model trained for this project.

## Future work

Potential improvements include structured playtesting, a standardized assessment separate from adaptive practice, more branching conversations, accessibility refinements, and further automated tests.

## License and asset attribution

See `LICENSE` for the terms covering source code you have the rights to release. Third-party and Roblox-owned assets may be subject to separate terms; include credits and redistribution restrictions where applicable.
