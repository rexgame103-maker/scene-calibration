"""Verify source-review completeness, unchanged text and ZIP integrity."""
import hashlib
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from build_source_review import collect

manifest = json.loads((ROOT / "review/manifest.json").read_text(encoding="utf-8"))
html = (ROOT / "review/index.html").read_text(encoding="utf-8")
match = re.search(r'<script id="review-data" type="application/json">(.*?)</script>', html, re.S)
assert match, "Embedded review data is missing"
embedded = json.loads(match[1])
current = collect()
assert embedded["files"] == current, "Embedded source differs from current project files"
expected = [{key: value for key, value in record.items() if key not in {"text", "symbols"}} for record in current]
assert manifest["files"] == expected, "File manifest differs from current source"

# Report only the path of a suspected credential, never credential content.
credential_patterns = [
    re.compile(r"\bgh[pousr]_[A-Za-z0-9]{30,}\b"),
    re.compile(r"\bgithub_pat_[A-Za-z0-9_]{40,}\b"),
    re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    re.compile(r"\bAKIA[A-Z0-9]{16}\b"),
]
for record in current:
    if "text" in record:
        for pattern in credential_patterns:
            assert not pattern.search(record["text"]), "Possible credential in " + record["path"]

delivery = ROOT / "deliveries/scene-calibration-source.zip"
if delivery.exists():
    with zipfile.ZipFile(delivery) as archive:
        expected_names = {"scene-calibration/" + record["path"] for record in current}
        expected_names.update({"scene-calibration/review/index.html", "scene-calibration/review/manifest.json"})
        assert set(archive.namelist()) == expected_names, "ZIP contents differ from complete project inventory"
        for record in current:
            raw = archive.read("scene-calibration/" + record["path"])
            assert hashlib.sha256(raw).hexdigest() == record["sha256"], "ZIP file differs: " + record["path"]
        for generated in ["review/index.html", "review/manifest.json"]:
            assert archive.read("scene-calibration/" + generated) == (ROOT / generated).read_bytes(), generated
        assert archive.testzip() is None, "ZIP CRC verification failed"
    print("SOURCE_ZIP_INTEGRITY_OK")
print(f"SOURCE_MANIFEST_OK files={len(current)} source_text=unchanged credential_patterns=clear")

if "--git-index" in sys.argv:
    listing = subprocess.run(["git", "ls-files", "--stage", "-z"], cwd=ROOT, check=True, capture_output=True).stdout
    staged = {}
    for entry in listing.split(b"\0"):
        if not entry:
            continue
        header, path = entry.split(b"\t", 1)
        staged[path.decode("utf-8")] = header.split()[1].decode("ascii")
    expected_paths = {record["path"] for record in current} | {"review/index.html", "review/manifest.json"}
    assert set(staged) == expected_paths, "Git staging inventory differs from source delivery"
    for path, object_id in staged.items():
        raw = (ROOT / path).read_bytes()
        expected_id = hashlib.sha1(b"blob " + str(len(raw)).encode("ascii") + b"\0" + raw).hexdigest()
        assert object_id == expected_id, "Git changed file bytes: " + path
    print(f"SOURCE_GIT_INDEX_OK files={len(staged)} exact_bytes=verified")
