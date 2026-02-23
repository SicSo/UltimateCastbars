#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from datetime import date
from pathlib import Path


# Accepts: "## Unreleased" or "## [Unreleased]"
UNRELEASED_H2_RE = re.compile(r"(?m)^##\s*(?:\[\s*Unreleased\s*\]|Unreleased)\s*$")
H2_RE = re.compile(r"(?m)^##\s+(.+?)\s*$")

TOC_VERSION_RE = re.compile(r"(?m)^(##\s*Version:\s*)(.+?)\s*$")


def pick_lua_long_bracket_delims(text: str) -> tuple[str, str]:
    """
    Picks [=[ ... ]=] style delimiters that won't conflict with content.
    """
    eq = 1
    while f"]={'=' * eq}]" in text:
        eq += 1
    open_delim = f"[{'=' * eq}["
    close_delim = f"]{'=' * eq}]"
    return open_delim, close_delim


def update_toc_version(toc_text: str, version: str) -> tuple[str, bool]:
    """
    Replace '## Version: ...' with '## Version: {version}'
    """
    def repl(m: re.Match) -> str:
        return f"{m.group(1)}{version}"

    new_text, n = TOC_VERSION_RE.subn(repl, toc_text, count=1)
    return new_text, (n > 0)


def extract_unreleased_block(md: str) -> tuple[str, str, str]:
    """
    Returns (before_unreleased, unreleased_body, after_unreleased)

    unreleased_body = text after '## Unreleased' up to (but not including) next '## ...'
    """
    m = UNRELEASED_H2_RE.search(md)
    if not m:
        raise SystemExit("ERROR: Could not find '## Unreleased' / '## [Unreleased]' header in CHANGELOG.md")

    start_body = m.end()

    # Find next H2 after Unreleased to bound its section
    m2 = H2_RE.search(md, pos=start_body)
    if not m2:
        raise SystemExit("ERROR: Could not find next '## ...' header after Unreleased section in CHANGELOG.md")

    before = md[:m.start()].rstrip("\n")
    body = md[start_body:m2.start()].strip("\n")
    after = md[m2.start():].lstrip("\n")
    return before, body, after


def build_unreleased_template() -> str:
    return (
        "## Unreleased\n\n"
        "---\n"
    )


def build_version_section(version: str, date_str: str, unreleased_body: str) -> str:
    """
    Builds the new released section from the Unreleased body.
    Keeps whatever headings you wrote under Unreleased (Added/Fixed/etc).
    """
    notes = unreleased_body.strip()
    if not notes:
        notes = "### Added\n- (no notes)\n"

    # If the unreleased body already ends with a separator, don't duplicate.
    notes_stripped = notes.rstrip()
    if re.search(r"(?m)^\s*---\s*$", notes_stripped.splitlines()[-1]) if notes_stripped else False:
        # already ends in ---
        notes_out = notes_stripped + "\n"
    else:
        notes_out = notes_stripped + "\n\n---\n"

    return f"## Version {version} - [{date_str}]\n\n{notes_out}"


def promote_unreleased(md: str, version: str, date_str: str) -> tuple[str, str]:
    """
    Converts Unreleased into a new version section and reinserts an empty Unreleased.
    Returns (updated_changelog_md, release_notes_md).
    """
    _, unreleased_body, after = extract_unreleased_block(md)

    unreleased_template = build_unreleased_template()
    version_section = build_version_section(version, date_str, unreleased_body)

    updated = (unreleased_template + "\n\n" + version_section + "\n\n" + after).strip() + "\n"
    release_notes = version_section.strip() + "\n"
    return updated, release_notes


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


def is_unreleased_section(section: str) -> bool:
    first_line = section.splitlines()[0].strip()
    return bool(UNRELEASED_H2_RE.match(first_line))


def keep_latest_versions(md: str, keep: int) -> str:
    """
    Keep only the first `keep` *released* H2 sections (top of file = latest),
    skipping the Unreleased section.
    Preserves any content *before* the first H2 (e.g. title/intro) as a header block.
    """
    matches = list(H2_RE.finditer(md))
    if not matches:
        return md.strip() + "\n"

    header_block = md[:matches[0].start()].rstrip("\n")
    sections = split_into_h2_sections(md)

    released_sections = [s for s in sections if not is_unreleased_section(s)]
    kept = released_sections[:keep]

    out_parts = []
    if header_block.strip():
        out_parts.append(header_block.strip("\n"))
    out_parts.extend(kept)

    return "\n\n".join(out_parts).strip() + "\n"


def main() -> None:
    ap = argparse.ArgumentParser(
        description="Release helper: promote Unreleased -> Version X+[date], update .toc Version, write RELEASE_NOTES.md, generate CHANGELOG.lua from latest released entries."
    )
    ap.add_argument("--version", required=True, help="Release version number, e.g. 2.4.0")
    ap.add_argument("--changelog", default="CHANGELOG.md", help="Path to CHANGELOG.md")
    ap.add_argument("--toc", default="UltimateCastbars/UltimateCastbars.toc", help="Path to your .toc file")
    ap.add_argument("--lua-out", default="UltimateCastbars/CHANGELOG.lua", help="Output Lua file path")
    ap.add_argument("--keep", type=int, default=10, help="How many latest released versions to copy into Lua")
    ap.add_argument("--date", default=None, help="Release date as DD-MM-YYYY (default: today)")
    ap.add_argument("--release-notes-out", default="RELEASE_NOTES.md", help="Output file for just this release's notes")
    args = ap.parse_args()

    version = args.version.strip()
    changelog_path = Path(args.changelog)
    toc_path = Path(args.toc)
    lua_out_path = Path(args.lua_out)
    release_notes_path = Path(args.release_notes_out)

    # Date format: DD-MM-YYYY
    if args.date:
        date_str = args.date.strip()
        if not re.fullmatch(r"\d{2}-\d{2}-\d{4}", date_str):
            raise SystemExit("ERROR: --date must be DD-MM-YYYY (e.g. 23-02-2026)")
    else:
        today = date.today()
        date_str = f"{today.day:02d}-{today.month:02d}-{today.year:04d}"

    # 1) Read + update CHANGELOG.md (promote Unreleased -> Version; re-add Unreleased)
    md = changelog_path.read_text(encoding="utf-8").replace("\r\n", "\n")
    md_updated, release_notes = promote_unreleased(md, version, date_str)

    changelog_path.write_text(md_updated, encoding="utf-8")
    release_notes_path.write_text(release_notes, encoding="utf-8")

    # 2) Update TOC version
    toc_text = toc_path.read_text(encoding="utf-8").replace("\r\n", "\n")
    toc_updated, did_toc = update_toc_version(toc_text, version)
    if not did_toc:
        raise SystemExit("ERROR: Could not find a '## Version: ...' line in the .toc file")

    toc_path.write_text(toc_updated.strip() + "\n", encoding="utf-8")

    # 3) Take latest N released versions and write into Lua
    latest_md = keep_latest_versions(md_updated, keep=args.keep)

    open_delim, close_delim = pick_lua_long_bracket_delims(latest_md)
    lua_text = (
        "local _, UCB = ...\n\n"
        f"UCB.CHANGELOG_TEXT = {open_delim}\n"
        f"{latest_md.rstrip()}\n"
        f"{close_delim}\n"
    )
    lua_out_path.write_text(lua_text, encoding="utf-8")

    print(f"Updated {changelog_path} (promoted Unreleased -> Version {version} - [{date_str}] and re-added fresh Unreleased)")
    print(f"Updated {toc_path} (## Version: {version})")
    print(f"Wrote {release_notes_path} (this release notes only)")
    print(f"Wrote {lua_out_path} (latest {args.keep} released versions)")


if __name__ == "__main__":
    main()