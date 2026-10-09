SCENE CALIBRATION / PAGE 03 WHITEBOX KIT

These are standalone explanatory models for the design dossier. They do not
replace any models in the game. The accepted spaces are the player studio,
the office and the conservation lab. Detail scenes reuse those spaces.

Open scene-calibration-whiteboxes.blend in Blender 4.5 or later. Use the Scene
selector to switch between the numbered studies; press Numpad 0 for the saved
camera. All materials, geometry, cameras and lighting are stored in the file.

01 Studio hub
02 Office workstation stage
03 Fully restored office
04 Visible desk-side wear detail
05 Middle shelf detail
06 Conservation lab: reported standard
07 Conservation lab: reconstructed actual
08 Direct and reflected light study
09 Wide cold panel / soft-shadow study

Regenerate with:
blender --background --python build_whitebox.py

Room footprints and relative placements come from the accepted case data.
Geometry is simplified for legibility. Light paths explain clue relationships;
they are not a heat or material-degradation simulation. Models and renders
are original Blender work, without imported game models or screenshots.

The presentation SVG embeds its PNG renders and keeps all text, rules,
arrows, circles and number badges as editable vector elements.
