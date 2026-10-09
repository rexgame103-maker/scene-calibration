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

All six applications share `classic_mail_theme.tres`: light gray work areas,
square beveled buttons, inset content panels and regular Tahoma-style text.
The mail application uses `scenes/ui/terminal_mail_client.tscn`, an editable
native Godot layout with a toolbar, a resizable message list, sender/recipient/
subject fields, and a scrolling reading pane. `classic_mail_theme.tres` and
the three `classic_*.svg` surfaces provide square, beveled desktop controls.
The existing title bar and transparent icons are retained.

`scripts/terminal_mail_client.gd` manages selection and folder filtering.
Inbox lists all available messages, Read Mail filters by `is_read`, and
Archived filters by completed cases. A visible message is automatically marked
read after 1.2 seconds at the end of its body. Long mail must be scrolled to the
end; closing or leaving the reader cancels the timer. Mark as Read remains
available explicitly. Reading does not accept the assignment.

The mail shortcut uses a 10-pixel red dot when unread messages exist. Reading
the last unread message hides it, and newly available unread mail shows it again.
Read updates keep the reading pane and its scroll position. Profile/GameFlow
operations are connected through `studio_computer_ui.gd`.
`tests/smoke_terminal_mail.gd` checks pointer input, actions, filtering, automatic
read and dot updates, language changes and layout. `smoke_terminal_apps.gd`
checks all five other applications and native purchase/expansion/reset actions.

The computer now opens on its desktop, with six application shortcuts, a Start
menu and a taskbar. Each application has its own retained content and window.
`scripts/terminal_app_window.gd` handles title-bar dragging, maximize/restore,
and fitting windows into the desktop workspace. Close removes only that app;
minimize retains it for restoration through the taskbar or desktop shortcut.
Reentering the computer shows the desktop with running apps minimized.

Mail is automatically marked read only while its window is the active app and
the reader has reached the end. Minimizing, closing, leaving the computer, or
switching to another application stops automatic reading. Background profile
updates refresh app data without restoring minimized windows.
`tests/smoke_terminal_desktop.gd` checks these flows with actual pointer input,
all six applications, both languages, and 1280x720 / 1024x600 viewports.
