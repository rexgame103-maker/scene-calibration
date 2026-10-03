# Computer terminal UI atlas

`terminal_atlas.png` is the user-provided transparent component sheet used by
`scripts/studio_computer_ui.gd`. The interface keeps all labels and interactive
controls as native Godot controls and uses cropped `AtlasTexture` regions for
frames and button surfaces.

`terminal_icons_sheet.png` is the transparent icon extraction generated from
the supplied artwork. `icons/*.png` contains normalized 256 x 256 transparent
icons without their former button-tile backgrounds. Rebuild them with
`tools/export_terminal_icons.ps1` when the source sheet changes.

The source atlas must keep its 1448 x 1086 pixel layout because crop rectangles
are defined in `studio_computer_ui.gd`.
