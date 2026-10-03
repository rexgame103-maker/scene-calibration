"""Build an offline source browser, hash manifest, and complete project ZIP.

Uses only Python's standard library. The HTML embeds source text and viewer
assets so file:// browsing works without a server or external dependencies.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED_ROOTS = {".git", ".godot", "Backups", "deliveries", "android"}
GENERATED = {"review/index.html", "review/manifest.json"}
TEXT_EXTENSIONS = {
    ".gd", ".gdshader", ".gdshaderinc", ".tscn", ".tres", ".godot", ".cfg",
    ".json", ".md", ".py", ".js", ".cjs", ".mjs", ".css", ".html", ".txt", ".toml", ".yml",
    ".yaml", ".cs", ".cpp", ".h", ".glsl", ".uid", ".import",
}
TEXT_NAMES = {".gitignore", ".gitattributes", ".editorconfig"}
MODULES = [
    {"title": "启动与游戏流程", "description": "从开始菜单进入工作室，再接取案件。", "paths": ["project.godot", "scripts/game_flow.gd", "scripts/scene_transition.gd", "scenes/start_menu/start_menu_office.tscn"]},
    {"title": "案件、资料与线索", "description": "JSON 驱动资料展示、线索发现和家具解锁。", "paths": ["scripts/case_manager.gd", "scripts/case_file_ui.gd", "scripts/case_archive_view.gd", "data/cases/office_case_001.json"]},
    {"title": "家具与现场重构", "description": "家具创建、摆放、空间条件与步骤奖励。", "paths": ["scripts/main.gd", "scripts/furniture_factory.gd", "scripts/reconstruction_zone.gd", "scripts/reconstruction_manager.gd", "scripts/scene_clue_point.gd"]},
    {"title": "玩家工作室与存档", "description": "工作室布置、电脑应用、商品与玩家进度。", "paths": ["scripts/calibrator_studio.gd", "scripts/studio_computer_ui.gd", "scripts/player_profile.gd", "scripts/studio_furniture_factory.gd", "data/progression/studio_catalog.json"]},
    {"title": "界面与图形资源", "description": "报纸界面、透明家具图标、暂停与画面效果。", "paths": ["scripts/first_case_flow_ui.gd", "scripts/catalog_item.gd", "scripts/furniture_icon_library.gd", "scripts/pause_menu.gd", "scripts/hand_drawn_post_process.gd"]},
    {"title": "运行与验证", "description": "阅读说明、查看验证脚本及源码交付工具。", "paths": ["docs/SOURCE_GUIDE.md", "tests/smoke_furniture_handdrawn.gd", "tools/build_source_review.py", "README.md"]},
]


def included(path: Path) -> bool:
    parts = path.relative_to(ROOT).parts
    if path.is_symlink() or parts[0] in EXCLUDED_ROOTS or "__pycache__" in parts:
        return False
    if path.name.startswith(".env") and path.name != ".env.example":
        return False
    return path.suffix.lower() not in {".pyc", ".key", ".p12", ".pfx"}


def paths() -> list[Path]:
    return sorted((path for path in ROOT.rglob("*") if path.is_file() and included(path)
                   and path.relative_to(ROOT).as_posix() not in GENERATED),
                  key=lambda path: path.relative_to(ROOT).as_posix().lower())


def symbols(text: str, suffix: str) -> list[dict]:
    output = []
    for number, line in enumerate(text.splitlines(), 1):
        label = None
        if suffix == ".gd":
            match = re.match(r"\s*(?:static\s+)?(func|signal|class_name)\s+(\w+)", line)
            if match:
                label = f"{match[1]} {match[2]}"
        elif suffix == ".py":
            match = re.match(r"\s*(?:async\s+)?(def|class)\s+(\w+)", line)
            if match:
                label = f"{match[1]} {match[2]}"
        elif suffix == ".tscn":
            match = re.match(r'\[node name="([^"]+)"', line)
            if match:
                parent = re.search(r'parent="([^"]+)"', line)
                label = (parent[1] + "/" if parent else "") + match[1]
        elif suffix == ".godot" and line.startswith("["):
            label = line
        if label:
            output.append({"line": number, "label": label})
    return output


def collect() -> list[dict]:
    records = []
    for path in paths():
        relative = path.relative_to(ROOT).as_posix()
        raw = path.read_bytes()
        record = {"path": relative, "size": len(raw), "sha256": hashlib.sha256(raw).hexdigest(), "extension": path.suffix.lower()}
        if path.suffix.lower() in TEXT_EXTENSIONS or path.name in TEXT_NAMES:
            try:
                text = raw.decode("utf-8-sig")
                if "\0" not in text:
                    record.update(text=text, lines=len(text.splitlines()), symbols=symbols(text, path.suffix.lower()))
            except UnicodeDecodeError:
                pass
        records.append(record)
    return records


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--date", default="2026-10-03", help="Review snapshot date (YYYY-MM-DD)")
    parser.add_argument("--zip", action="store_true", help="Write deliveries/scene-calibration-source.zip")
    args = parser.parse_args()
    records = collect()
    known = {record["path"] for record in records}
    for module in MODULES:
        assert all(path in known for path in module["paths"]), module["title"]
    payload = {"name": "错位现场", "date": args.date, "files": records, "modules": MODULES,
               "exclusions": sorted(EXCLUDED_ROOTS), "entry": "scenes/start_menu/start_menu_office.tscn"}
    encoded = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).replace("<", "\\u003c").replace("\u2028", "\\u2028").replace("\u2029", "\\u2029")
    css = (ROOT / "review/viewer.css").read_text(encoding="utf-8")
    js = (ROOT / "review/viewer.js").read_text(encoding="utf-8")
    template = (ROOT / "review/template.html").read_text(encoding="utf-8")
    replacements = {"__REVIEW_CSS__": css, "__REVIEW_DATA__": encoded, "__REVIEW_JS__": js}
    html = re.sub(r"__REVIEW_(?:CSS|DATA|JS)__", lambda match: replacements[match[0]], template)
    (ROOT / "review/index.html").write_text(html, encoding="utf-8", newline="\n")
    manifest = dict(payload)
    manifest["files"] = [{key: value for key, value in record.items() if key not in {"text", "symbols"}} for record in records]
    (ROOT / "review/manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    if args.zip:
        delivery = ROOT / "deliveries/scene-calibration-source.zip"
        delivery.parent.mkdir(exist_ok=True)
        with zipfile.ZipFile(delivery, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for path in paths() + [ROOT / name for name in sorted(GENERATED)]:
                archive.write(path, "scene-calibration/" + path.relative_to(ROOT).as_posix())
        print("SOURCE_ZIP=" + str(delivery))
        print("SOURCE_ZIP_SHA256=" + hashlib.sha256(delivery.read_bytes()).hexdigest())
    print(f"SOURCE_REVIEW_OK files={len(records)} text={sum('text' in record for record in records)} bytes={sum(record['size'] for record in records)}")


if __name__ == "__main__":
    main()
