# Scene Calibration

*Read the traces. Connect the evidence. Reconstruct the scene.*

**Scene Calibration** is a 3D deduction and reconstruction game built with **Godot 4.7 and GDScript**. Accept commissions from a retro computer in your studio, examine photographs and documents, and investigate the physical traces left behind. Each clue unlocks new furnishings and helps you reconstruct the relationships between objects.

The playable campaign includes your personal studio and two case locations:

- **The Cleared Office:** rebuild an office emptied before the police arrived, using incomplete photographs, furniture wear, computer records and printed documents.
- **The Miscalibrated Restoration Room:** reconstruct a conservation workspace, then compare photographic evidence and adjust lighting to investigate a discrepancy in the restoration records.
- **Your Studio:** arrange your workspace, read mail, purchase equipment and keep an album of completed reconstructions between assignments.

English is the default language. Simplified Chinese is available in Settings.

## Source Review

- **[Source guide](docs/SOURCE_GUIDE.md):** startup flow, directory structure, module relationships and a core code index.
- **[Offline browser instructions](review/README.md):** a directory tree, complete source text with line numbers, function and node navigation, and full-text search.
- **[File manifest](review/manifest.json):** file paths, byte counts and SHA-256 checksums.
- **[Development notes](docs/DEVELOPMENT_NOTES.md):** interaction rules, editor configuration and development history.
- **[English code review map](docs/CODE_REVIEW.md):** feature entry points, corresponding game captures and verified checks.
- **[Portfolio pages](design/presentation/README.md):** editable English newspaper SVGs and PNG previews.

After downloading the complete project, open `review/index.html` to browse the source offline. GitHub displays `.gd`, `.tscn`, `.json` and `.gdshader` files directly; download the HTML source browser to use it locally.

## Run the Project

1. Install Godot 4.7 and import `project.godot` from the repository root.
2. Wait for the initial asset import to finish, then press **F5**.
3. Enter your studio from the start menu, set up your workspace and open the computer to read and accept commissions.

The startup scene is `scenes/start_menu/start_menu_office.tscn`. Case locations share `scenes/main.tscn`, and the player studio uses `scenes/studio/calibrator_studio.tscn`. The project uses the `gl_compatibility` renderer.

## Repository Structure

```text
scene-calibration/
├── project.godot          # Project settings, startup scene and eight autoloads
├── scripts/              # Game logic, input, furniture, saves and runtime UI
├── scenes/               # Start menu, studio, case locations and UI nodes
├── data/
│   ├── cases/            # Cases, clues, evidence, unlocks and reconstruction steps
│   ├── progression/      # Campaign progression and studio shop inventory
│   ├── localization/     # English translations and language settings
│   └── audio/            # Sound manifests and event configuration
├── assets/               # Models, images, fonts, photographs, audio and UI atlases
├── materials/            # Godot material resources
├── shaders/              # Shaders and hand-drawn rendering effects
├── tests/                # Feature checks and visual previews
├── tools/                # Asset processing, scene rendering and source delivery
├── design/               # Design studies and interface references
├── docs/                 # Source guides and development notes
└── review/               # Offline source browser
```

## Suggested Reading Order

1. [project.godot](project.godot): startup configuration and global managers.
2. [game_flow.gd](scripts/game_flow.gd): transitions between the start menu, studio and cases.
3. [case_manager.gd](scripts/case_manager.gd) and [office case data](data/cases/office_case_001.json): clues, evidence and furniture unlocks.
4. [main.gd](scripts/main.gd) and [furniture_factory.gd](scripts/furniture_factory.gd): furniture creation and scene interaction.
5. [reconstruction_manager.gd](scripts/reconstruction_manager.gd): spatial conditions and reconstruction steps.
6. [player_profile.gd](scripts/player_profile.gd): progress, inventory and saved layouts.
7. [terminal_app_window.gd](scripts/terminal_app_window.gd) and [terminal_mail_client.gd](scripts/terminal_mail_client.gd): desktop windows, taskbar behavior and mail reading state.
8. [game_language.gd](scripts/game_language.gd) and [game_audio.gd](scripts/game_audio.gd): default English, language preferences and event-driven sound effects.

The active campaign is limited to the studio, office and restoration room. Legacy experimental case data remains in the project, but its commission emails, case index and replay entries are disabled. Related tasks and album records from older saves are excluded from the normal flow. Unfinished terminal mini-games are also unavailable.

## Offline Delivery and Verification

Run `python tools/build_source_review.py --date YYYY-MM-DD --zip` to regenerate the source browser, file manifest and `deliveries/scene-calibration-source.zip`. The generator reads the project source without changing game logic.

The repository includes the models, images, scenes, import settings and `.uid` files required to run the project. Godot import caches, Git internals, local backups and delivery archives are excluded from version control.

The `tests/` directory contains checks from different development stages. Including a test does not imply that it currently passes; use the actual execution logs for the checks you run.

## Licensing

This repository does not introduce an open-source license. Public source access does not change the existing licensing terms of the code or assets.
