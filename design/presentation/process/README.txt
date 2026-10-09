SCENE CALIBRATION / ENVIRONMENT PRODUCTION STUDIES

Presentation: ../04-production-process.svg
Preview: ../04-production-process.png
Blender: three-scenes-production-studies.blend

The Blender file contains nine scenes: STUDIO, OFFICE and RESTORATION, each
with occupancy blocks, form and structure, and detailed clay stages. Use
the Scene selector to switch stages and Numpad 0 for the saved camera.

Stage 1: one plain 8-vertex box per semantic object, without assembled parts.
Stage 2: recognizable silhouettes, supports, openings and basic construction.
Stage 3: drawers, keys, books, props, frame details, foliage and surface cues.
Stage 4: separate Godot screenshots of the full authored game environments.

The first three stages are newly reconstructed production studies created
for this presentation, not recovered versions of earlier project assets.
Their layouts and camera angles follow the three authored game environments.
The process kit is separate from gameplay and does not replace game models.

To regenerate the Blender studies:
blender --background --python build_process_whiteboxes.py

To recapture the final Godot scenes, run capture_final_scenes.gd with the
project's Godot executable and a rendering display (not --headless).
The capture script reads scenes and adjusts camera framing in memory. It
does not run any scene-building tools or save modified scene resources.

Final source scenes:
res://scenes/studio/player_studio_concept.tscn
res://scenes/cases/office_restored_concept.tscn
res://scenes/cases/gallery_restored_concept.tscn

The SVG embeds all twelve PNG images. Text, rules, frame borders, labels
and arrows remain native SVG elements for editing after importing to Figma.
