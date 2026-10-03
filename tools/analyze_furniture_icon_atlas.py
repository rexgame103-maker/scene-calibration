"""Read generated alpha pixels and write atlas regions; never modify artwork."""
import json
from pathlib import Path
import numpy as np
from PIL import Image

folder = Path(__file__).resolve().parents[1] / "assets/ui/furniture_handdrawn"
manifest = {}
for sheet in json.loads((folder / "sheets.json").read_text(encoding="utf-8")):
    image = Image.open(folder / (sheet["batch"] + ".png")).convert("RGBA")
    alpha = np.asarray(image)[:, :, 3]
    height, width = alpha.shape
    assert np.count_nonzero(alpha == 0) > alpha.size * .25, "Atlas must be transparent"
    # Components, rather than fixed cell cuts, preserve protruding feet/handles.
    remaining = (alpha > 8).ravel().copy()
    boxes = [[] for _ in range(9)]
    for seed in np.flatnonzero(remaining):
        if not remaining[seed]:
            continue
        remaining[seed] = False
        stack = [int(seed)]
        x0, y0, x1, y1, count = width, height, 0, 0, 0
        while stack:
            pixel = stack.pop()
            y, x = divmod(pixel, width)
            x0, y0, x1, y1 = min(x0, x), min(y0, y), max(x1, x+1), max(y1, y+1)
            count += 1
            for neighbor in (pixel-1 if x else -1, pixel+1 if x < width-1 else -1,
                             pixel-width if y else -1, pixel+width if y < height-1 else -1):
                if neighbor >= 0 and remaining[neighbor]:
                    remaining[neighbor] = False
                    stack.append(neighbor)
        if count < 10:
            continue
        center_x = (x0 + x1) / 2
        center_y = (y0 + y1) / 2
        column = min(2, max(0, int(center_x * 3 / width)))
        row = min(2, max(0, int(center_y * 3 / height)))
        boxes[row * 3 + column].append((x0, y0, x1, y1))
    for kind, regions in zip(sheet["items"], boxes):
        assert regions, kind
        left = max(0, min(v[0] for v in regions) - 3)
        top = max(0, min(v[1] for v in regions) - 3)
        right = min(width, max(v[2] for v in regions) + 3)
        bottom = min(height, max(v[3] for v in regions) + 3)
        manifest[kind] = {"sheet": sheet["batch"], "region": [left, top, right-left, bottom-top]}
    print(sheet["batch"], image.size, "transparent", round(float((alpha == 0).mean()), 3))
(folder / "regions.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print("ATLAS_REGIONS", len(manifest))
