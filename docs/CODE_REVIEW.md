# Scene Calibration — Code Review Map

A Godot 4.7 / GDScript spatial deduction game. The player studio is the hub; the office and heritage restoration room are the two formal cases presented in the design dossier.

## Start here

1. [project.godot](../project.godot): the startup scene and eight Autoload services.
2. [game_flow.gd](../scripts/game_flow.gd): studio, assignment and scene transitions.
3. [case_manager.gd](../scripts/case_manager.gd): data loading, evidence, clues and furniture unlocks.
4. [main.gd](../scripts/main.gd): placing objects, inspecting surfaces and calibrating lights.
5. [reconstruction_manager.gd](../scripts/reconstruction_manager.gd): spatial, clue and lighting conditions.
6. [player_profile.gd](../scripts/player_profile.gd): persistent progress, inventory and studio layout.

## Six observable systems

| Feature | Read the implementation | Corresponding in-game capture |
|---|---|---|
| Camera-visible clue investigation | [SceneCluePoint](../scripts/scene_clue_point.gd#L202-L234): `_is_runtime_visible`, `is_visible_from_camera`, `investigate`; rendered mesh occlusion and surface-normal checks gate both visibility and clicks | [Desk-side wear](../design/presentation/gameplay/screenshots/inspection.png) |
| Evidence → clues → furniture | [CaseManager](../scripts/case_manager.gd#L253-L265): `view_evidence`, `discover_clue`, `_evaluate_furniture_unlocks`; [case JSON](../data/cases/office_case_001.json) | [Office evidence photo](../design/presentation/gameplay/screenshots/evidence.png) |
| Reconstruction step conditions | [ReconstructionManager](../scripts/reconstruction_manager.gd#L105-L116): zone conditions, required clues and lighting must all agree; [ReconstructionZone](../scripts/reconstruction_zone.gd) checks local bounds and orientation | [Restored office](../design/presentation/gameplay/screenshots/office-restored-ui.png) |
| Lighting as evidence | [ReconstructionManager](../scripts/reconstruction_manager.gd#L252-L280): light aim, approximate projected shadow length and reflection conditions, alongside parameter ranges | [Restoration-room calibration](../design/presentation/gameplay/screenshots/calibration.png) |
| A functional desktop | [TerminalAppWindow](../scripts/terminal_app_window.gd#L72-L88): maximize/restore and title-bar dragging; [StudioComputerUI](../scripts/studio_computer_ui.gd): six apps, taskbar and close/minimize lifecycle | [Mail launched from the desktop](../design/presentation/gameplay/screenshots/mail.png) |
| Persistent profile and archive | [PlayerProfile](../scripts/player_profile.gd#L87-L108): JSON storage; `mark_mail_read` and `complete_case` persist reading state, completion, rewards and album entries | [Photograph archived in the studio album](../design/presentation/gameplay/screenshots/album.png) |

The denser [code page](../design/presentation/05-code-architecture.svg) embeds 81 actual source lines across six systems and four small runtime captures. Gaps and visual line wrapping are explicitly marked. Its [source manifest](../design/presentation/05-code-architecture-sources.json) records file hashes, exact original lines and image hashes. The final [gameplay page](../design/presentation/06-gameplay-demonstration.svg) uses eight fresh frames to follow the office case from assignment to album, with the restoration room labelled as a separate continuation.

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

The [fresh presentation capture](../design/presentation/gameplay/capture_gameplay_sequence.gd) also verifies a chair preview against the normal placement validator, genuine desk-side investigation from a visible camera angle, both cases' final reconstruction conditions, the office submission, saved photograph, profile completion and return to the studio album. It uses existing debug placement/calibration helpers to stage the screenshots; it does not prove the case was completed manually. Its [capture manifest](../design/presentation/gameplay/capture-manifest.json) records the actual engine version, resolution and states.

To rerun the six checks on Windows:

```powershell
& tools/run_audio_smoke.ps1 -Tests @('smoke_game_audio', 'smoke_clue_visibility', 'smoke_computer_clue_click', 'smoke_terminal_desktop', 'smoke_terminal_mail', 'smoke_language_settings')
```

The runner uses the configured local Godot executable; override `-Godot` if it is installed elsewhere. These results describe the selected checks, not every historical test in `tests/`.
