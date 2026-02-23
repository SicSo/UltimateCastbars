#!/usr/bin/env bash
set -euo pipefail

VERSION=""
DATE=""

usage() {
  echo "Usage: $0 --version X.Y.Z [--date DD-MM-YYYY]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:-}"; shift 2;;
    --date)
      DATE="${2:-}"; shift 2;;
    -h|--help)
      usage;;
    *)
      echo "Unknown arg: $1"
      usage;;
  esac
done

[[ -n "$VERSION" ]] || usage

TOC="UltimateCastbars/UltimateCastbars.toc"
LUA_OUT="UltimateCastbars/CHANGELOGS.lua"
PY="py"  # or python3

# 1) run updater
if [[ -n "$DATE" ]]; then
  $PY update.py --version "$VERSION" --date "$DATE" --toc "$TOC" --lua-out "$LUA_OUT"
else
  $PY update.py --version "$VERSION" --toc "$TOC" --lua-out "$LUA_OUT"
fi

# 2) commit
git add CHANGELOG.md "$TOC" "$LUA_OUT" RELEASE_NOTES.md
git commit -m "chore(release): $VERSION"

# 3) tag (fails if tag already exists)
git tag "v$VERSION"

# 4) push
git push origin main "v$VERSION"

echo "Done: committed + tagged v$VERSION and pushed."