#!/usr/bin/env bash
# Install this package's skills into the local Codex skills directory.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$REPO_ROOT/skills"
FORCE=false

if [ -n "${CODEX_SKILLS_DIR:-}" ]; then
  TARGET_DIR="$CODEX_SKILLS_DIR"
elif [ -n "${CODEX_HOME:-}" ]; then
  if command -v cygpath >/dev/null 2>&1; then
    TARGET_DIR="$(cygpath -u "$CODEX_HOME")/skills"
  else
    TARGET_DIR="$CODEX_HOME/skills"
  fi
else
  TARGET_DIR="$HOME/.codex/skills"
fi

if [ "${1:-}" = "--force" ]; then
  FORCE=true
fi

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: skills/ not found at $SOURCE_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
target_root="$(cd "$TARGET_DIR" && pwd -P)"

installed=0
skipped=0

for skill_dir in "$SOURCE_DIR"/*; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue

  name="$(basename "$skill_dir")"
  target="$TARGET_DIR/$name"

  if [ -e "$target" ]; then
    if [ "$FORCE" != true ]; then
      echo "SKIP  $name exists at $target (use --force to replace)"
      skipped=$((skipped + 1))
      continue
    fi
    resolved_parent="$(cd "$(dirname "$target")" && pwd -P)"
    if [ "$resolved_parent" != "$target_root" ] || [ -z "$name" ]; then
      echo "Error: refusing to remove unsafe target: $target" >&2
      exit 1
    fi
    rm -rf "$target"
  fi

  cp -R "$skill_dir" "$target"
  echo "OK    $name -> $target"
  installed=$((installed + 1))
done

echo "Installed: $installed | Skipped: $skipped | Target: $TARGET_DIR"
