"""Generate this game's SFX through the existing shared Medium Gradio service.

Run with soundfx/stable-audio-3/.venv/Scripts/python.exe. Never installs a model,
restarts a shared service, or overwrites another project's outputs. Candidates
are scored by timing/waveform only; the audition lets a human assess timbre.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import html
import json
import math
import os
from pathlib import Path
import shutil
import time
from datetime import datetime
import zipfile

import numpy as np
import soundfile as sf
from gradio_client import Client

ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "data/audio/sound_pack_spec.json"
COMMON = "TrackType: SFX. {action} Close-miked natural sound in a quiet room. No music, no speech, no singing, no dramatic reverb."
MODEL_REVISION = "a30034d70bd58f6e6f967ef28ecaa6c52c185d6c"


def write_json(path: Path, data: object) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def db(value: float) -> float:
    return round(20 * math.log10(max(value, 1e-10)), 3)


def envelope(x: np.ndarray, sr: int, hop_ms: int = 5) -> np.ndarray:
    hop = sr * hop_ms // 1000
    usable = x[:len(x) // hop * hop]
    return np.sqrt(np.mean(usable.reshape(-1, hop, x.shape[1]) ** 2, axis=(1, 2)))


def prepare(path: Path, item: dict, sr: int) -> tuple[np.ndarray, dict]:
    x, rate = sf.read(path, dtype="float32", always_2d=True)
    if rate != sr or not np.isfinite(x).all() or len(x) < sr // 10:
        raise ValueError(f"Invalid generated waveform: {path}")
    clipping = float(np.mean(np.abs(x) >= 0.999))
    x -= np.mean(x, axis=0, keepdims=True)
    if item.get("mono"):
        x = np.mean(x, axis=1, keepdims=True)
    peak = float(np.max(np.abs(x)))
    if peak < 1e-5:
        raise ValueError(f"Silent generated waveform: {path}")
    hop = sr * 5 // 1000
    env = envelope(x, sr)
    mode = item.get("mode", "oneshot")
    max_frames = min(len(x), int(item["max_seconds"] * sr))
    if mode == "loop":
        # The central section excludes generation startup/tail, then end/head
        # overlap is equal-power crossfaded. No silence padding on loops.
        start = max(0, (len(x) - max_frames) // 2)
        end = start + max_frames
        segment = x[start:end].copy()
        cross = int(0.8 * sr)
        theta = np.linspace(0, math.pi / 2, cross, dtype=np.float32)[:, None]
        seam = segment[-cross:] * np.cos(theta) + segment[:cross] * np.sin(theta)
        cut = np.concatenate((segment[cross:-cross], seam))
        activity = float(np.mean(env > np.max(env) * 0.12))
        variation = float(np.std(env) / max(np.mean(env), 1e-8))
        score = activity - variation * 0.4 - clipping * 20
    else:
        # Choose the most energetic short window, preserving the lead-in and
        # ending inside the desired practical action duration.
        width = max(1, min(len(env), max_frames // hop))
        energy = np.convolve(env ** 2, np.ones(width), mode="valid")
        window = int(np.argmax(energy))
        # Device cycles contain a loud switch click followed by quieter motor
        # sound. Preserve that tail rather than mistaking it for silence.
        threshold = 0.015 if mode == "texture" else 0.065
        active = np.flatnonzero(env[window:window + width] > float(np.max(env)) * threshold)
        first = window + int(active[0]) if len(active) else window
        last = window + int(active[-1]) if len(active) else window + width - 1
        start = max(0, first * hop - int(0.012 * sr))
        end = min(len(x), start + max_frames, (last + 1) * hop + int(0.05 * sr))
        if mode == "texture":
            end = min(len(x), max(end, start + int(max_frames * 0.75)))
        if end - start < int(0.08 * sr):
            end = min(len(x), start + int(0.08 * sr))
        cut = x[start:end].copy()
        captured = float(np.sum(cut ** 2) / max(np.sum(x ** 2), 1e-8))
        active_ratio = float(np.mean(envelope(cut, sr) > np.max(env) * 0.08))
        score = captured + active_ratio * 0.15 - clipping * 20
        fade_in = min(int(0.003 * sr), len(cut) // 4)
        fade_out = min(int((0.08 if mode == "texture" else 0.025) * sr), len(cut) // 4)
        cut[:fade_in] *= np.linspace(0, 1, fade_in, dtype=np.float32)[:, None]
        cut[-fade_out:] *= np.linspace(1, 0, fade_out, dtype=np.float32)[:, None]
    raw_rms = float(np.sqrt(np.mean(cut ** 2)))
    target_rms = 10 ** ((-32 if mode == "loop" else -22 if item["category"] in {"paper_ui", "terminal"} else -20) / 20)
    ceiling = 10 ** ((-14 if mode == "loop" else -4) / 20)
    gain = min(target_rms / max(raw_rms, 1e-10), ceiling / max(float(np.max(np.abs(cut))), 1e-10))
    cut *= gain
    if mode != "loop":
        cut = np.pad(cut, ((int(0.006 * sr), int(0.025 * sr)), (0, 0)))
    metrics = {
        "trim_start_seconds": round(start / sr, 4), "trim_end_seconds": round(end / sr, 4),
        "waveform_score": round(score, 6), "raw_clipped_fraction": round(clipping, 8),
        "peak_dbfs": db(float(np.max(np.abs(cut)))), "rms_dbfs": db(float(np.sqrt(np.mean(cut ** 2)))),
        "duration_seconds": round(len(cut) / sr, 4), "channels": cut.shape[1],
        "processing_gain_db": db(gain), "loop_crossfade_seconds": 0.8 if mode == "loop" else 0,
    }
    return cut, metrics


def generate(client: Client, raw_path: Path, item: dict, seed: int) -> str:
    prompt = COMMON.format(action=item["prompt"])
    if not raw_path.exists():
        response = client.predict(prompt=prompt, seconds_total=int(item["seconds"]),
                                  cfg_scale=1.0, steps=8, seed=seed, duration_padding_sec=1.0,
                                  file_format="wav", file_naming="verbose", cut_to_seconds_total=True,
                                  api_name="/generate")
        shutil.copyfile(response[0], raw_path)
    return prompt


def build_audition(folder: Path, bank: dict, sr: int) -> None:
    chunks, timeline, cards = [], [], []
    position = 0.0
    silence = np.zeros((int(0.55 * sr), 2), dtype=np.float32)
    selected_preview = {"paper_click", "page_turn", "dossier_open", "archive_stamp", "terminal_click", "mail_arrive", "place_wood", "place_chair", "place_small", "clue_collect", "camera_shutter", "case_complete", "printer_print", "water_dispenser", "amb_studio"}
    highlights = []
    for order, entry in enumerate(bank["sounds"], 1):
        audio, _ = sf.read(folder / entry["file"], dtype="float32", always_2d=True)
        if audio.shape[1] == 1:
            audio = np.repeat(audio, 2, axis=1)
        # Audition applies the documented initial in-game gain. The production
        # WAV itself retains editing headroom and is not attenuated a second time.
        audio *= 10 ** (entry["gain_db"] / 20)
        if entry["loop"]:
            audio = audio[:int(6 * sr)].copy()
            audio[:int(0.3 * sr)] *= np.linspace(0, 1, int(0.3 * sr))[:, None]
            audio[-int(0.3 * sr):] *= np.linspace(1, 0, int(0.3 * sr))[:, None]
        duration = len(audio) / sr
        timeline.append([order, f"{position:.3f}", f"{position + duration:.3f}", entry["label"], entry["file"]])
        chunks.extend((audio, silence))
        position += duration + 0.55
        if entry["event"] in selected_preview and entry["variant"] == 1:
            highlights.extend((audio, silence))
        safe_label = html.escape(entry["label"])
        cards.append(f'<article data-category="{entry["category"]}"><div><b>{order:02d} · {safe_label}</b><small>{html.escape(entry["event"])} · {entry["duration_seconds"]:.2f} 秒 · {"环境循环" if entry["loop"] else "单次"} · 推荐 {entry["gain_db"]} dB</small></div><audio controls preload="none" src="{entry["file"]}"></audio></article>')
    sf.write(folder / "全部音效试听.wav", np.concatenate(chunks), sr, subtype="PCM_16")
    sf.write(folder / "精选试听.wav", np.concatenate(highlights), sr, subtype="PCM_16")
    with (folder / "试听时间轴.csv").open("w", encoding="utf-8-sig", newline="") as output:
        writer = csv.writer(output)
        writer.writerow(["序号", "开始秒", "结束秒", "音效", "文件"])
        writer.writerows(timeline)
    buttons = '<button data-filter="all">全部</button>' + ''.join(f'<button data-filter="{key}">{html.escape(value)}</button>' for key, value in bank["categories"].items())
    page = '''<!doctype html><html lang="zh-CN"><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>错位现场 · 音效试听</title><style>body{background:#181713;color:#ece0ca;font:16px system-ui;margin:0;padding:35px 6vw}h1{font-family:serif}p{color:#b7ad98;line-height:1.7}button{background:#d4c4a6;border:0;border-radius:4px;padding:10px 18px;margin:4px;cursor:pointer}article{display:flex;align-items:center;justify-content:space-between;gap:20px;padding:17px;border-bottom:1px solid #514b3d}small{display:block;color:#b7ad98;margin-top:8px}audio{max-width:100%}.notes{padding:20px;background:#25231d}section{margin-top:24px}@media(max-width:750px){article{display:block}article audio{margin-top:12px}}</style><h1>错位现场 · 纸页与痕迹</h1><p>纸张界面 / 家具摆放 / 案件调查 / 办公设备 / 室内环境<br>使用项目现有 Stable Audio 3 Medium 生成，并裁切、均衡音量和处理循环。</p><div class="notes">精选组合试听（使用推荐初始音量）<br><audio controls src="精选试听.wav"></audio><p>下方逐项试听播放素材原始音量。成品已做波形检查；音色和场景混音请通过试听确认。环境循环可以连续播放检查接缝。</p></div><nav>BUTTONS</nav><section>CARDS</section><script>document.querySelectorAll('[data-filter]').forEach(b=>b.onclick=()=>{document.querySelectorAll('audio').forEach(a=>a.pause());document.querySelectorAll('article').forEach(c=>c.hidden=b.dataset.filter!=='all'&&b.dataset.filter!==c.dataset.category)});document.querySelectorAll('article audio').forEach(a=>{a.onplay=()=>document.querySelectorAll('audio').forEach(o=>{if(o!==a)o.pause()});if(a.closest('article').dataset.category==='ambience')a.loop=true;});</script></html>'''
    (folder / "试听.html").write_text(page.replace("BUTTONS", buttons).replace("CARDS", "\n".join(cards)), encoding="utf-8")


def finish_pack(folder: Path, spec: dict, entries: list[dict], records: list[dict], sr: int) -> None:
    events = {}
    for item in spec["items"]:
        sounds = [entry for entry in entries if entry["event"] == item["id"]]
        events[item["id"]] = {"label": item["label"], "category": item["category"],
                              "streams": [entry["resource"] for entry in sounds],
                              "gain_db": item["gain_db"], "cooldown_ms": item["cooldown_ms"],
                              "loop": item.get("mode") == "loop", "spatial": item.get("mono", False)}
    bank = {"schema_version": 1, "pack_name": spec["pack_name"], "sample_rate": sr,
            "format": "WAV PCM_16", "categories": spec["categories"], "events": events, "sounds": entries,
            "model": spec["model"], "model_revision": MODEL_REVISION,
            "qa": "Automated waveform/timing/format/loop-seam checks; no claim of human semantic listening."}
    write_json(folder / "sound_bank.json", bank)
    write_json(folder / "制作记录.json", {"spec": spec, "model_revision": MODEL_REVISION, "entries": records})
    build_audition(folder, bank, sr)
    table = ["| ID | 音效 | 数量 | 用途类别 | 推荐增益 |", "|---|---|---:|---|---:|"]
    for item in spec["items"]:
        table.append(f'| `{item["id"]}` | {item["label"]} | {item.get("variants", 1)} | {spec["categories"][item["category"]]} | {item["gain_db"]} dB |')
    notes = f'''# 错位现场 · 纸页与痕迹

本套包含 **{len(spec["items"])} 类事件、{len(entries)} 个 WAV**，其中 3 条是约 20 秒的环境循环。使用已经安装的 Stable Audio 3 Medium 本地工具制作，没有安装另一套工具。

## 文件

- `试听.html`：分组逐项试听；环境条目自动循环。
- `精选试听.wav` / `全部音效试听.wav`：按推荐初始增益拼接的试听，不是游戏素材。
- `试听时间轴.csv`：全部试听对应时间。
- `sound_bank.json`：事件 ID、Godot 资源路径、变体、推荐增益、冷却时间和空间化类型。
- 六个英文分类文件夹：成品 WAV，44.1 kHz / PCM 16 位；家具与设备为单声道，界面与环境为双声道。
- `制作记录.json`：原始提示词、随机种子、候选评分、裁切与增益；原始候选保留在工具输出目录 `_candidates`，不放入成品 ZIP 和游戏项目。

## 接入建议

成品目录为项目 `assets/audio/scene_calibration/`，JSON 路径已经对应该目录。本项目的运行接入位于自动加载的 `scripts/game_audio.gd`，接入位置与音量设置见 `docs/AUDIO_PACK.md`。其他项目可用 `AudioStreamPlayer` 播放界面和提示，`AudioStreamPlayer3D` 播放家具与设备，继续共用原有生成工具。循环 WAV 在 Godot 导入面板使用 Forward；项目内 `.wav.import` 已设置。

同一事件有两个变体时随机播放。读取 `gain_db` 作为初始音量，不要把所有素材同时按 0 dB 播放；悬停、移动、碰撞根据 `cooldown_ms` 限流。拖拽音是单次短纹理，只有实际移动一定距离时触发，不能每帧重播。环境每个场景只开一条，切场景淡入淡出 0.8–1.2 秒，暂停时环境应同步减弱或暂停。

- 工作室、开始背景：`amb_studio`；第一关办公室：`amb_office`；第二关修复室：`amb_gallery`。背景不是配乐，没有剧情对白。
- 报纸按钮、档案、照片和暂停：`paper_click` / `page_turn` / `dossier_open` / `paper_cancel`。悬停音默认可关闭。
- 终端界面与新委托：`terminal_click` / `terminal_window_open` / `mail_arrive`。邮件提示只在有新邮件时触发。
- 家具落地根据材质选择 `place_wood` / `place_chair` / `place_cabinet` / `place_metal` / `place_small` / `place_paper`，常规落地不表示答案正确。
- `placement_invalid` 只用于碰撞等禁止摆放条件；不能用来提示家具与答案区域是否匹配。
- `clue_discover` 必须沿用可见性和观察角度判定；隐藏痕迹不播放。`clue_collect` 在玩家收集成功后播放；重复打开已读资料不重复播发现音。
- `case_complete` 只在案件完成归档时播放一次；复原照片用 `camera_shutter`，归档用 `archive_stamp`。
- 打印机、饮水机等只在实际使用设备的流程播放，摆进场景仍使用材质落地音，避免混淆。

## 制作与检查

每类生成两个不同种子的候选；根据有效能量、动作时长和削波情况选择或保留变体。单次音去除直流分量、裁掉多余前后段、加短淡入淡出、保留少量静音边界并统一电平。循环使用 0.8 秒等功率交叉淡化，校验首尾跳变。波形评分不等于人耳音色判断，逐项试听用于确认音色；没有声明已由人工听审。

来源：Powered by Stability AI / Stable Audio 3 Medium，使用本地缓存模型 `{MODEL_REVISION}`。模型的 Stability AI Community License 与 Gemma 条款随工具安装目录保留；本说明不额外授予素材独占权。

## 事件清单

''' + "\n".join(table) + "\n"
    (folder / "使用与接入说明.md").write_text(notes, encoding="utf-8")
    project_folder = ROOT / "assets/audio/scene_calibration"
    project_folder.mkdir(parents=True, exist_ok=True)
    old_bank_path = project_folder / "sound_bank.json"
    old_hashes = {}
    if old_bank_path.exists():
        old_bank = json.loads(old_bank_path.read_text(encoding="utf-8"))
        old_hashes = {entry["file"]: entry["sha256"] for entry in old_bank.get("sounds", [])}
    for entry in entries:
        src = folder / entry["file"]
        dst = project_folder / entry["file"]
        dst.parent.mkdir(parents=True, exist_ok=True)
        if (dst.exists() and dst.read_bytes() != src.read_bytes()
                and hashlib.sha256(dst.read_bytes()).hexdigest() != old_hashes.get(entry["file"])):
            raise FileExistsError(f"Refusing to overwrite a different existing SFX: {dst}")
        shutil.copyfile(src, dst)
        if entry["loop"]:
            # Stable resource import UID is allocated by Godot when imported.
            imported = Path(str(dst) + ".import")
            if not imported.exists():
                imported.write_text(f'''[remap]

importer="wav"
type="AudioStreamWAV"
path=""

[deps]

source_file="{entry['resource']}"

[params]

force/8_bit=false
force/mono=false
force/max_rate=false
edit/trim=false
edit/normalize=false
edit/loop_mode=2
edit/loop_begin=0
edit/loop_end=-1
compress/mode=0
''', encoding="utf-8")
            else:
                settings = imported.read_text(encoding="utf-8")
                # Godot's importer enum has Detect From WAV as its first value;
                # Forward is 2, while AudioStreamWAV.LOOP_FORWARD itself is 1.
                settings = settings.replace("edit/loop_mode=1", "edit/loop_mode=2")
                imported.write_text(settings, encoding="utf-8")
    for name in ("sound_bank.json", "使用与接入说明.md"):
        shutil.copyfile(folder / name, project_folder / name)
    docs = ROOT / "docs/AUDIO_PACK.md"
    # Preserve the separately maintained runtime integration guide on rebuilds.
    if not docs.exists():
        docs.write_text(notes, encoding="utf-8")
    write_json(folder / "校验结果.json", validate(folder, bank, sr))
    archive = folder.parent / (folder.name + ".zip")
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as zipout:
        for path in sorted(folder.rglob("*")):
            if (path.is_file() and "_candidates" not in path.parts
                    and path.name != "progress.json" and path.suffix != ".log"):
                zipout.write(path, path.relative_to(folder))
    print(json.dumps({"status": "complete", "events": len(spec["items"]), "files": len(entries),
                      "folder": str(folder), "project": str(project_folder), "zip": str(archive)}, ensure_ascii=False), flush=True)


def validate(folder: Path, bank: dict, sr: int) -> dict:
    seen, metrics = set(), []
    for entry in bank["sounds"]:
        path = folder / entry["file"]
        info = sf.info(path)
        x, _ = sf.read(path, always_2d=True)
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest in seen or digest != entry["sha256"]:
            raise AssertionError(f"Duplicate or changed audio: {path}")
        seen.add(digest)
        peak = float(np.max(np.abs(x)))
        rms = float(np.sqrt(np.mean(x ** 2)))
        if info.samplerate != sr or info.subtype != "PCM_16" or info.channels != entry["channels"]:
            raise AssertionError(f"Wrong WAV format: {path}")
        if not np.isfinite(x).all() or not 1e-5 < rms or not 0 < peak < 0.8:
            raise AssertionError(f"Silent, clipped or invalid waveform: {path}")
        result = {"file": entry["file"], "duration": info.duration, "peak_dbfs": db(peak), "rms_dbfs": db(rms), "sha256": digest}
        if entry["loop"]:
            seam = float(np.max(np.abs(x[-1] - x[0])))
            typical = float(np.percentile(np.abs(np.diff(x, axis=0)), 99))
            if seam > max(0.003, typical * 3):
                raise AssertionError(f"Loop seam discontinuity: {path}: {seam}")
            result.update(loop_seam_step=seam, within_file_step_p99=typical)
        elif np.max(np.abs(x[:100])) > 1e-5 or np.max(np.abs(x[-100:])) > 1e-5:
            raise AssertionError(f"Non-silent one-shot boundary: {path}")
        project = ROOT / entry["resource"].removeprefix("res://")
        if not project.exists() or hashlib.sha256(project.read_bytes()).hexdigest() != digest:
            raise AssertionError(f"Project copy mismatch: {project}")
        metrics.append(result)
    assert all(event["streams"] for event in bank["events"].values())
    return {"passed": True, "files": len(metrics), "sample_rate": sr, "checks": ["format", "non_silent", "finite", "no_clipping", "unique_waveforms", "sha256", "one_shot_boundaries", "loop_seams", "project_copies", "event_coverage"], "sounds": metrics}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tool-root", type=Path, default=Path(r"E:\VoiceboxWorkspace\soundfx"))
    parser.add_argument("--service", default="http://127.0.0.1:7861")
    parser.add_argument("--output", type=Path, help="Reuse this pack's directory to resume from its saved candidates.")
    parser.add_argument("--rebuild", action="store_true", help="Reprocess saved candidates only; no generation calls.")
    args = parser.parse_args()
    os.environ["NO_PROXY"] = "127.0.0.1,localhost"
    os.environ["no_proxy"] = "127.0.0.1,localhost"
    spec = json.loads(SPEC.read_text(encoding="utf-8"))
    sr = spec["sample_rate"]
    folder = args.output or args.tool_root / "outputs" / ("错位现场_音效套_" + datetime.now().strftime("%Y%m%d_%H%M%S"))
    folder.mkdir(parents=True, exist_ok=True)
    raw_folder = folder / "_candidates"
    raw_folder.mkdir(exist_ok=True)
    client = None if args.rebuild else Client(args.service, verbose=False)
    entries, records = [], []
    start = time.monotonic()
    write_json(folder / "progress.json", {"status": "generating", "items_total": len(spec["items"]), "done": 0})
    for index, item in enumerate(spec["items"]):
        candidates = []
        for variant in range(2):
            seed = spec["seed_base"] + index * 101 + variant
            path = raw_folder / f'{item["id"]}_{seed}.wav'
            if args.rebuild and not path.exists():
                raise FileNotFoundError(path)
            prompt = COMMON.format(action=item["prompt"]) if args.rebuild else generate(client, path, item, seed)
            array, measures = prepare(path, item, sr)
            candidates.append((array, {"seed": seed, "raw_file": str(path.relative_to(folder)), "prompt": prompt, **measures}))
        candidates.sort(key=lambda candidate: candidate[1]["waveform_score"], reverse=True)
        selected = candidates[:item.get("variants", 1)]
        record = {"event": item["id"], "candidates": [measure for _, measure in candidates], "selected_seeds": [measure["seed"] for _, measure in selected]}
        records.append(record)
        for variant, (array, measures) in enumerate(selected, 1):
            filename = f'{item["id"]}_{variant:02d}.wav' if item.get("variants", 1) > 1 else item["id"] + ".wav"
            relative = item["category"] + "/" + filename
            path = folder / relative
            path.parent.mkdir(exist_ok=True)
            sf.write(path, array, sr, subtype="PCM_16")
            entries.append({"event": item["id"], "variant": variant, "label": item["label"] + (f" · {variant}" if item.get("variants", 1) > 1 else ""),
                            "category": item["category"], "file": relative, "resource": "res://assets/audio/scene_calibration/" + relative,
                            "loop": item.get("mode") == "loop", "spatial": item.get("mono", False), "gain_db": item["gain_db"],
                            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), **measures})
        write_json(folder / "progress.json", {"status": "generating", "items_total": len(spec["items"]), "done": index + 1,
                                               "last_event": item["id"], "elapsed_seconds": round(time.monotonic() - start, 1)})
        print(f'[{index + 1:02d}/{len(spec["items"])}] {item["id"]} · {item["label"]} · {measures["duration_seconds"]}s', flush=True)
    finish_pack(folder, spec, entries, records, sr)
    write_json(folder / "progress.json", {"status": "complete", "items_total": len(spec["items"]), "done": len(spec["items"]), "elapsed_seconds": round(time.monotonic() - start, 1)})


if __name__ == "__main__":
    main()
