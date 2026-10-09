# Scene Calibration — Code Review Map

A Godot 4.7 / GDScript spatial deduction game. The player studio is the hub; the office and heritage restoration room are the two formal cases presented in the design dossier.

## Start here

1. [project.godot](../project.godot): the startup scene and eight Autoload services.
2. [game_flow.gd](../scripts/game_flow.gd): studio, assignment and scene transitions.
3. [case_manager.gd](../scripts/case_manager.gd): data loading, evidence, clues and furniture unlocks.
4. [main.gd](../scripts/main.gd): placing objects, inspecting surfaces and calibrating lights.
5. [reconstruction_manager.gd](../scripts/reconstruction_manager.gd): spatial, clue and lighting conditions.
6. [player_profile.gd](../scripts/player_profile.gd): persistent progress, inventory and studio layout.

## Four observable features

| Feature | Read the implementation | Corresponding in-game capture |
|---|---|---|
| Evidence → clues → furniture | [CaseManager](../scripts/case_manager.gd): `view_evidence`, `discover_clue`, `_evaluate_furniture_unlocks`; [case JSON](../data/cases/office_case_001.json) | [Office evidence photo](../design/presentation/code/screenshots/evidence.png) |
| Camera-visible clue investigation | [SceneCluePoint](../scripts/scene_clue_point.gd): `_is_runtime_visible`, `is_visible_from_camera`, `investigate`; rendered mesh occlusion and surface-normal checks gate both visibility and clicks | [Desk-side wear](../design/presentation/code/screenshots/visible-clue.png) |
| Spatial reconstruction and lighting | [ReconstructionZone](../scripts/reconstruction_zone.gd): local position bounds and orientation; [ReconstructionManager](../scripts/reconstruction_manager.gd): required zones, clues, light parameters, projected shadow and reflection conditions | [Restoration room calibration](../design/presentation/code/screenshots/reconstruction.png) |
| A functional desktop | [TerminalAppWindow](../scripts/terminal_app_window.gd): maximize/restore and title-bar dragging; [StudioComputerUI](../scripts/studio_computer_ui.gd): six apps, taskbar and close/minimize lifecycle; [TerminalMailClient](../scripts/terminal_mail_client.gd): reading and unread state | [Mail launched from the desktop](../design/presentation/code/screenshots/desktop.png) |

The [code page](../design/presentation/05-code-architecture.svg) embeds actual source excerpts and all four captures. Its [source manifest](../design/presentation/05-code-architecture-sources.json) records file hashes, original line numbers and the screenshot capture script.

## Other services

- [GameLanguage](../scripts/game_language.gd): defaults to English, persists the chosen locale and supports live translation.
- [GameAudio](../scripts/game_audio.gd): UI events, material sounds, spatial effects, ambience fades and volume settings. Deferred UI binding resolves instance IDs so removed controls are ignored safely.
- [SOURCE_GUIDE.md](SOURCE_GUIDE.md): the complete directory and module guide.
- [review/index.html](../review/index.html): download the whole project and open this file locally for line-numbered source, symbol navigation and full-text search.

## Verified for this update — 2026-10-09

The following checks completed with exit code 0 in an isolated project/user directory; the rendered checks used the real Windows OpenGL renderer:

- `smoke_game_audio`: sound events, lifecycle, pause, fades and preferences, including a freed-control regression.
- `smoke_clue_visibility`: hidden/occluded clues reject direct investigation and real clicks; a reachable camera angle enables investigation.
- `smoke_computer_clue_click`: the office computer clue can be opened and collected with real pointer events.
- `smoke_terminal_desktop`: launch, drag, maximize/restore, minimize, taskbar, close, retained state and unread visibility; six bilingual apps at two resolutions.
- `smoke_terminal_mail`: real rows/buttons, read/archive filtering and assignment actions.
- `smoke_language_settings`: default English, dynamic translated UI and persisted locale.

The presentation capture also checks that the desk-side clue can genuinely be investigated from its camera angle and that the restoration room satisfies its final reconstruction conditions before capture. It uses existing debug placement/calibration helpers to stage the screenshots; it does not prove the case was completed manually.

To rerun the six checks on Windows:

```powershell
& tools/run_audio_smoke.ps1 -Tests @('smoke_game_audio', 'smoke_clue_visibility', 'smoke_computer_clue_click', 'smoke_terminal_desktop', 'smoke_terminal_mail', 'smoke_language_settings')
```

The runner uses the configured local Godot executable; override `-Godot` if it is installed elsewhere. These results describe the selected checks, not every historical test in `tests/`.
