#!/usr/bin/env bash
# Lightweight smoke tests for local Codex skill usability.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${1:-$REPO_ROOT/skills}"

if [ ! -d "$SKILLS_DIR" ]; then
  echo "Error: skills directory not found: $SKILLS_DIR" >&2
  exit 1
fi

expected_skills=(
  browser-cdp
  story
  story-cover
  story-deslop
  story-import
  story-long-analyze
  story-long-scan
  story-long-write
  story-review
  story-setup
  story-short-analyze
  story-short-scan
  story-short-write
)

for name in "${expected_skills[@]}"; do
  skill_dir="$SKILLS_DIR/$name"
  skill_md="$skill_dir/SKILL.md"

  if [ ! -f "$skill_md" ]; then
    echo "Error: missing skill: $name at $skill_md" >&2
    exit 1
  fi

  if ! grep -q '^name: ' "$skill_md" || ! grep -q '^description:' "$skill_md"; then
    echo "Error: invalid frontmatter in $skill_md" >&2
    exit 1
  fi

  if [ ! -f "$skill_dir/agents/openai.yaml" ]; then
    echo "Error: missing agents/openai.yaml for $name" >&2
    exit 1
  fi
done

required_files=(
  "$SKILLS_DIR/story/SKILL.md"
  "$SKILLS_DIR/story-deslop/references/banned-words.md"
  "$SKILLS_DIR/story-review/references/quality-rubric.md"
  "$SKILLS_DIR/story-setup/references/templates/AGENTS.md.tmpl"
  "$SKILLS_DIR/story-setup/references/templates/agents/story-explorer.md"
  "$SKILLS_DIR/browser-cdp/scripts/setup-cdp-chrome.js"
)

for file in "${required_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "Error: expected file missing: $file" >&2
    exit 1
  fi
done

check_files=()
for name in "${expected_skills[@]}"; do
  check_files+=("$SKILLS_DIR/$name/SKILL.md")
done

if grep -n '^version:\|^metadata:' "${check_files[@]}" >/tmp/oh-story-smoke-frontmatter.txt; then
  echo "Error: Claude/OpenClaw-only frontmatter remains:" >&2
  cat /tmp/oh-story-smoke-frontmatter.txt >&2
  exit 1
fi

if ! grep -q '非官方 Codex 移植版' "$REPO_ROOT/README.md"; then
  echo "Error: README attribution notice missing" >&2
  exit 1
fi

echo "Smoke test passed: ${#expected_skills[@]} oh-story skills usable from $SKILLS_DIR"
