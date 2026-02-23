#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from datetime import date
from pathlib import Path


UNRELEASED_HEADER_RE = re.compile(
    r"(?m)^(##\s*(?:\[\s*Unreleased\s*\]|Unreleased)\s*)$"
)

TOC_VERSION_RE = re.compile(
    r"(?m)^(##\s*Version:\s*)(.+?)\s*$"
)

H2_RE = re.compile(r"(?m)^##\s+(.+?)\s*$")


def pick_lua_long_bracket_delims(text: str) -> tuple[str, str]:
    """
    Picks [=[ ... ]=] style delimiters that won't conflict with content.
    """
    eq = 1
    while f"]={'='*eq}]" in text:
        eq += 1
    open_delim = f"[{'='*eq}["
    close_delim = f"]{'='*eq}]"
    return open_delim, close_delim


def replace_unreleased(changelog: str, version: str, date_str: str) -> tuple[str, bool]:
    """
    Replace first Unreleased H2 header with '## Version {version} - [{date_str}]'
    """
    new_header = f"## Version {version} - [{date_str}]"

    m = UNRELEASED_HEADER_RE.search(changelog)
    if not m:
        return changelog, False

    start, end = m.span(1)
    updated = changelog[:start] + new_header + changelog[end:]
    return updated, True


def split_into_h2_sections(md: str) -> list[str]:
    """
    Split markdown into sections starting with H2 (## ...).
    Returns list of section strings, each beginning with '## ...'
    """
    matches = list(H2_RE.finditer(md))
    if not matches:
        return []

    sections: list[str] = []
    for i, m in enumerate(matches):
        s = m.start()
        e = matches[i + 1].start() if i + 1 < len(matches) else len(md)
        section = md[s:e].strip("\n")
        sections.append(section)
    return sections


def keep_latest_versions(md: str, keep: int) -> str:
    """
    Keep only the first `keep` H2 sections (top of file = latest).
    Preserves any content *before* the first H2 (e.g. title/intro) as a header block.
    """
    matches = list(H2_RE.finditer(md))
    if not matches:
        return md.strip() + "\n"

    header_block = md[:matches[0].start()].rstrip("\n")
    sections = split_into_h2_sections(md)

    kept = sections[:keep]
    out_parts = []
    if header_block.strip():
        out_parts.append(header_block.strip("\n"))
    out_parts.extend(kept)

    return "\n\n".join(out_parts).strip() + "\n"


def update_toc_version(toc_text: str, version: str) -> tuple[str, bool]:
    """
    Replace '## Version: ...' with '## Version: {version}'
    """
    def repl(m: re.Match) -> str:
        return f"{m.group(1)}{version}"

    new_text, n = TOC_VERSION_RE.subn(repl, toc_text, count=1)
    return new_text, (n > 0)


def main() -> None:
    ap = argparse.ArgumentParser(
        description="Release helper: update CHANGELOG.md + .toc version, then generate CHANGELOG.lua from latest entries."
    )
    ap.add_argument("--version", required=True, help="Release version number, e.g. 2.4.0")
    ap.add_argument("--changelog", default="CHANGELOG.md", help="Path to CHANGELOG.md")
    ap.add_argument("--toc", default="UltimateCastbars/UltimateCastbars.toc", help="Path to your .toc file")
    ap.add_argument("--lua-out", default="UltimateCastbars/CHANGELOG.lua", help="Output Lua file path")
    ap.add_argument("--keep", type=int, default=10, help="How many latest versions to copy into Lua")
    ap.add_argument("--date", default=None, help="Release date as DD-MM-YYYY (default: today)")
    args = ap.parse_args()

    version = args.version.strip()
    changelog_path = Path(args.changelog)
    toc_path = Path(args.toc)
    lua_out_path = Path(args.lua_out)

    # Date format: DD-MM-YYYY
    if args.date:
        date_str = args.date.strip()
        if not re.fullmatch(r"\d{2}-\d{2}-\d{4}", date_str):
            raise SystemExit("ERROR: --date must be DD-MM-YYYY (e.g. 23-02-2026)")
    else:
        today = date.today()
        date_str = f"{today.day:02d}-{today.month:02d}-{today.year:04d}"

    # 1) Read + update CHANGELOG.md (replace Unreleased)
    md = changelog_path.read_text(encoding="utf-8").replace("\r\n", "\n")
    md_updated, did_replace = replace_unreleased(md, version, date_str)

    if not did_replace:
        raise SystemExit(
            "ERROR: Could not find an '## Unreleased' or '## [Unreleased]' header in CHANGELOG.md"
        )

    # Write updated changelog back (with normalized newlines)
    changelog_path.write_text(md_updated.strip() + "\n", encoding="utf-8")

    # 2) Update TOC version
    toc_text = toc_path.read_text(encoding="utf-8").replace("\r\n", "\n")
    toc_updated, did_toc = update_toc_version(toc_text, version)
    if not did_toc:
        raise SystemExit("ERROR: Could not find a '## Version: ...' line in the .toc file")

    toc_path.write_text(toc_updated.strip() + "\n", encoding="utf-8")

    # 3) Take latest N versions and write into Lua
    latest_md = keep_latest_versions(md_updated, keep=args.keep)

    open_delim, close_delim = pick_lua_long_bracket_delims(latest_md)
    lua_text = (
        "local _, UCB = ...\n\n"
        f"UCB.CHANGELOG_TEXT = {open_delim}\n"
        f"{latest_md.rstrip()}\n"
        f"{close_delim}\n"
    )
    lua_out_path.write_text(lua_text, encoding="utf-8")

    print(f"Updated {changelog_path} (replaced Unreleased -> Version {version} - [{date_str}])")
    print(f"Updated {toc_path} (## Version: {version})")
    print(f"Wrote {lua_out_path} (latest {args.keep} versions)")


if __name__ == "__main__":
    main()