#!/bin/bash
# check-story-setup-deployment.sh — Codex 版 story-setup 部署契约检查
#
# v0.6.16 后上游 main 增强了拆文到写作模块链、推理型一致性检查和正文前置守卫。
# Codex 移植版保留这些可检查约束，但部署目标必须仍是 AGENTS.md
# 与 .codex/ 目录，不能恢复旧运行时项目内 hooks/settings 写入。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SETUP_SKILL="$REPO_ROOT/skills/story-setup/SKILL.md"
UPGRADING="$REPO_ROOT/skills/story-setup/UPGRADING.md"
PLUGIN_JSON="$REPO_ROOT/.codex-plugin/plugin.json"
HOOKS_JSON="$REPO_ROOT/hooks/hooks.json"
HOOK_SCRIPT="$REPO_ROOT/hooks/story-lifecycle-hook.cjs"
AGENT_DIR="$REPO_ROOT/skills/story-setup/references/templates/agents"
REFERENCE_DIR="$REPO_ROOT/skills/story-setup/references/agent-references"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "required file missing: $1"
}

require_file "$SETUP_SKILL"
require_file "$UPGRADING"
require_file "$PLUGIN_JSON"
require_file "$HOOKS_JSON"
require_file "$HOOK_SCRIPT"

for required in \
  "AGENTS.md" \
  ".codex/story-agents" \
  ".codex/story-rules" \
  ".codex/story-agent-references" \
  "references/agent-references/" \
  "agents_version: 15" \
  "setup_skill_version: 1.1.6" \
  "runtime: codex"; do
  if ! grep -qF "$required" "$SETUP_SKILL"; then
    fail "story-setup SKILL.md missing Codex deployment requirement: $required"
  fi
done

for forbidden in \
  ".claude/hooks" \
  ".claude/settings.local.json" \
  ".claude/agents" \
  ".claude/rules" \
  "CLAUDE.md" \
  "settings-hooks.json" \
  "target_cli: claude-code"; do
  if grep -qF "$forbidden" "$SETUP_SKILL" "$UPGRADING"; then
    fail "story-setup docs contain forbidden old-runtime deployment text: $forbidden"
  fi
done

if ! grep -qF '"hooks": "./hooks/hooks.json"' "$PLUGIN_JSON"; then
  fail "plugin manifest must load Codex lifecycle hooks via hooks/hooks.json"
fi

if ! node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" "$HOOKS_JSON" >/dev/null 2>&1; then
  fail "hooks/hooks.json is not valid JSON"
fi

node --check "$HOOK_SCRIPT" >/dev/null || fail "hook script has syntax errors"

[ -d "$AGENT_DIR" ] || fail "agent template directory missing"
[ -d "$REFERENCE_DIR" ] || fail "agent reference bundle missing"

agent_count="$(find "$AGENT_DIR" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
[ "$agent_count" = "7" ] || fail "expected 7 story agent templates, got $agent_count"

missing_refs=0
while IFS= read -r ref_path; do
  [ -z "$ref_path" ] && continue
  ref_name="$(basename "$ref_path")"
  if [ ! -f "$REFERENCE_DIR/$ref_name" ]; then
    echo "MISSING reference bundle file: $ref_name" >&2
    missing_refs=$((missing_refs + 1))
  fi
done < <(
  grep -RhoE 'story-setup/references/agent-references/[a-z0-9_-]+\.md' "$AGENT_DIR" "$REFERENCE_DIR" 2>/dev/null | sort -u
)

[ "$missing_refs" -eq 0 ] || fail "$missing_refs referenced agent reference files are missing"

if grep -RInE '(^tools: \[Read|^disallowedTools:|^model:|^memory:|subagent_type|WebSearch|webReader|Claude Code|OpenClaw|AskUserQuestion)' "$AGENT_DIR" "$REFERENCE_DIR" >/tmp/story-setup-contamination.$$ 2>/dev/null; then
  cat /tmp/story-setup-contamination.$$ >&2
  rm -f /tmp/story-setup-contamination.$$
  fail "old-runtime agent/frontmatter contamination detected"
fi
rm -f /tmp/story-setup-contamination.$$

echo "OK: story-setup deployment contract is Codex-safe"
