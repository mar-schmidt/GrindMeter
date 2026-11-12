"""Build and verify a reproducible, single-root WoW addon release ZIP."""
import hashlib
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    toc = (ROOT / "GrindMeter/GrindMeter.toc").read_text()
    version = re.search(r"^## Version: (\d+\.\d+\.\d+)$", toc, re.M)[1]
    if f'G.version = "{version}"' not in (ROOT / "GrindMeter/Core/Namespace.lua").read_text():
        raise ValueError("Namespace and TOC versions disagree")
    for line in toc.splitlines():
        if line and not line.startswith("#") and not (ROOT / "GrindMeter" / line).is_file():
            raise ValueError(f"TOC file missing: {line}")
    output = ROOT / "dist"
    output.mkdir(exist_ok=True)
    target = output / f"GrindMeter-{version}.zip"
    sources = [(p, p.relative_to(ROOT).as_posix()) for p in sorted((ROOT / "GrindMeter").rglob("*")) if p.is_file()]
    for name in ("README.md", "LICENSE", "CHANGELOG.md"):
        sources.append((ROOT / name, "GrindMeter/" + name))
    for name in ("API.md", "DATA.md", "IN_GAME_TESTING.md", "TEST_RESULTS.md", "THIRD_PARTY.md"):
        sources.append((ROOT / "docs" / name, "GrindMeter/docs/" + name))
    with zipfile.ZipFile(target, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for source, path in sorted(sources, key=lambda pair: pair[1]):
            if source.is_symlink() or any(x in {"__pycache__", ".DS_Store", ".git"} for x in source.parts):
                raise ValueError(f"Unexpected release file: {source}")
            info = zipfile.ZipInfo(path, date_time=(2026, 11, 12, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED; info.external_attr = 0o100644 << 16
            archive.writestr(info, source.read_bytes())
    with zipfile.ZipFile(target) as archive:
        if archive.testzip() is not None:
            raise ValueError("Corrupt ZIP")
        if {name.split("/")[0] for name in archive.namelist()} != {"GrindMeter"}:
            raise ValueError("Release must have a single GrindMeter root")
        if "GrindMeter/GrindMeter.toc" not in archive.namelist():
            raise ValueError("TOC is not directly below addon root")
    checksum = hashlib.sha256(target.read_bytes()).hexdigest()
    (output / "SHA256SUMS.txt").write_text(f"{checksum}  {target.name}\n")
    print(f"{target.name}: {len(sources)} files, {target.stat().st_size:,} bytes")
    print(f"SHA256 {checksum}")


if __name__ == "__main__":
    main()
