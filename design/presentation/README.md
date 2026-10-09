# Scene Calibration — Design Dossier

Six English newspaper pages, each 1920 × 1080 (16:9). SVG text, rules, annotations and code remain editable; images are embedded for standalone import into desktop Figma. PNG files are visual previews.

| Page | Editable SVG | Preview | Contents |
|---|---|---|---|
| 01 | [Cover](01-cover.svg) | [PNG](01-cover.png) | Game title, studio camera and project overview |
| 02 | [Inspiration & References](02-inspiration-references-v2-collage.svg) | [PNG](02-inspiration-references-v2-collage.png) | Everyday traces, Return of the Obra Dinn and House Flipper |
| 03 | [Mechanics & Level Loop](03-mechanics-level-loop.svg) | [PNG](03-mechanics-level-loop.png) | Blender diagrams; office and restoration case logic |
| 04 | [Production Process](04-production-process.svg) | [PNG](04-production-process.png) | Three environments in four stages; final Godot captures |
| 05 | [Code & Architecture](05-code-architecture.svg) | [PNG](05-code-architecture.png) | Six systems, 81 actual source lines, four smaller game captures and repository links |
| 06 | [Gameplay Demonstration](06-gameplay-demonstration.svg) | [PNG](06-gameplay-demonstration.png) | Eight fresh runtime frames; numbered office flow and restoration-room calibration |

The project presents a player studio hub and two formal cases: an office and a heritage restoration room. Old apartment experiment files are not a presented level.

Production stages 01–03 are retrospective Blender studies made for this dossier, not recovered historical versions of the game. Stage 04 and pages 05–06 images are actual Godot captures. Reference screenshots and their credits are documented in the page 02 source manifest.

Rebuild page 05 with `python design/presentation/build_code_page.py`, then render and audit with `node design/presentation/render_code.cjs`. Builders require Pillow for measuring text. Renderers use the installed Playwright/Edge runtime paths recorded in the scripts; these are local build dependencies, not game dependencies. Code excerpts are read directly from the current scripts and linked to matching line ranges in GitHub.

Rebuild page 06 with `python design/presentation/build_gameplay_page.py`, then render and audit with `node design/presentation/render_gameplay.cjs`. The fresh screenshots live in `gameplay/screenshots/`. `gameplay/capture_gameplay_sequence.gd` captures the actual studio, office and restoration-room runtime using an isolated user profile. Existing debug helpers stage furniture and lighting; normal placement, camera visibility, reconstruction, submission, photograph archive and studio-return checks remain active. The large office frame hides only the HUD. The capture manifest records this method; it is not a claim of manual playthrough.

The `*-sources.json` files identify screenshot sources and code ranges. The `*-audit.json` files report layout bounds, text overlaps and self-contained image checks. Preserve an entire page SVG when importing into Figma; its text uses Georgia, Arial and, on the code page, Consolas.
