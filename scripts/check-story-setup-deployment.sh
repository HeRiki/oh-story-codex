#!/usr/bin/env bash
# check-story-setup-deployment.sh — Codex-only story-setup deployment contract.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_DIR="$REPO_ROOT/skills/story-setup"
SKILL_FILE="$SKILL_DIR/SKILL.md"
UPGRADING_FILE="$SKILL_DIR/UPGRADING.md"
CODEX_DIR="$SKILL_DIR/references/codex"
AGENT_TEMPLATES="$SKILL_DIR/references/templates/agents"
RULES_DIR="$SKILL_DIR/references/templates/rules"
AGENT_REFS_DIR="$SKILL_DIR/references/agent-references"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_file() { [ -f "$1" ] || fail "required file missing: $1"; }
assert_dir() { [ -d "$1" ] || fail "required directory missing: $1"; }
assert_grep() { grep -Eq "$1" "$2" || fail "$3 ($2)"; }

PYBIN=""
for candidate in python3 python py; do
  if "$candidate" -c 'import sys; raise SystemExit(sys.version_info < (3, 10))' >/dev/null 2>&1; then
    PYBIN="$candidate"
    break
  fi
done
[ -n "$PYBIN" ] || fail "Python 3.10+ is required for story-setup deployment checks"

echo "Story setup deployment check"
echo "============================"
echo "Repo: $REPO_ROOT"

cd "$REPO_ROOT"

assert_file "$SKILL_FILE"
assert_file "$UPGRADING_FILE"
assert_file "$CODEX_DIR/AGENTS.md.tmpl"
assert_file "$CODEX_DIR/hooks/hooks.json"
assert_file "$CODEX_DIR/hooks/story_codex_hook.py"
assert_dir "$CODEX_DIR/agents"
assert_dir "$AGENT_TEMPLATES"
assert_dir "$RULES_DIR"
assert_dir "$AGENT_REFS_DIR"

for required in \
  'runtime: codex' \
  'agents_version: 17' \
  'setup_skill_version: 1.2.6' \
  'references/codex/AGENTS.md.tmpl' \
  'references/codex/agents/' \
  'references/codex/hooks/hooks.json' \
  'references/codex/hooks/story_codex_hook.py' \
  '.codex/agents/' \
  '.codex/hooks.json' \
  '.codex/skills/story-setup/references/agent-references/' \
  '.codex/story-agent-references/'; do
  grep -Fq -- "$required" "$SKILL_FILE" \
    || fail "story-setup SKILL.md missing deployment contract: $required ($SKILL_FILE)"
done
echo "  OK deployment contract anchors"

agent_count="$(find "$AGENT_TEMPLATES" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
[ "$agent_count" = "7" ] || fail "expected 7 story agent markdown templates, got $agent_count"
toml_count="$(find "$CODEX_DIR/agents" -maxdepth 1 -type f -name '*.toml' | wc -l | tr -d ' ')"
[ "$toml_count" = "7" ] || fail "expected 7 Codex TOML agents, got $toml_count"
rule_count="$(find "$RULES_DIR" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
[ "$rule_count" -ge "4" ] || fail "expected at least 4 story rule files, got $rule_count"
echo "  OK managed file counts"

"$PYBIN" -m json.tool "$CODEX_DIR/hooks/hooks.json" >/dev/null
"$PYBIN" - <<'PY'
from pathlib import Path
for name in (
    'skills/story-setup/references/codex/hooks/story_codex_hook.py',
    'scripts/generate-codex-agents.py',
):
    compile(Path(name).read_text(encoding='utf-8'), name, 'exec')
PY
echo "  OK Codex hook JSON/Python syntax"

"$PYBIN" "$REPO_ROOT/scripts/generate-codex-agents.py" \
  --source "$AGENT_TEMPLATES" \
  --dest "$TMP_DIR/agents" >/dev/null
diff -qr "$TMP_DIR/agents" "$CODEX_DIR/agents" >/dev/null \
  || fail "Codex TOML agents are stale; run scripts/generate-codex-agents.py"
echo "  OK generated Codex agents are deterministic"

"$PYBIN" - <<'PY'
import json
import re
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:
    tomllib = None

expected = {
    'chapter-extractor', 'character-designer', 'consistency-checker',
    'narrative-writer', 'story-architect', 'story-explorer', 'story-researcher',
}
found = set()

def parse_generated_toml(text, path):
    data = {}
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        raw = lines[i]
        if not raw.strip():
            i += 1
            continue
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$', raw)
        assert m, f'{path}: invalid TOML line {i + 1}: {raw!r}'
        key, value = m.group(1), m.group(2)
        if value == '"""':
            block = []
            i += 1
            while i < len(lines) and lines[i] != '"""':
                block.append(lines[i])
                i += 1
            assert i < len(lines), f'{path}: unterminated multiline string for {key}'
            data[key] = "\n".join(block)
            i += 1
            continue
        if value.startswith('"') or value.startswith('['):
            data[key] = json.loads(value)
            i += 1
            continue
        raise AssertionError(f'{path}: unsupported TOML value for {key}: {value!r}')
    return data

def read_agent(path):
    text = path.read_text(encoding='utf-8')
    if tomllib is not None:
        return tomllib.loads(text)
    return parse_generated_toml(text, path)

for path in Path('skills/story-setup/references/codex/agents').glob('*.toml'):
    data = read_agent(path)
    assert data.get('name'), path
    assert data.get('description'), path
    assert data.get('developer_instructions'), path
    found.add(data['name'])
assert found == expected, found
PY
echo "  OK Codex agent TOML schema"

missing_refs=0
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  ref_name="$(basename "$ref")"
  if [ ! -f "$AGENT_REFS_DIR/$ref_name" ]; then
    echo "MISSING reference bundle file: $ref_name" >&2
    missing_refs=$((missing_refs + 1))
  fi
done < <(
  grep -RhoE 'story-setup/references/agent-references/[A-Za-z0-9_-]+\.md' \
    "$AGENT_TEMPLATES" "$AGENT_REFS_DIR" "$CODEX_DIR/agents" 2>/dev/null | sort -u
)
[ "$missing_refs" -eq 0 ] || fail "$missing_refs referenced agent reference files are missing"
echo "  OK agent reference bundle integrity"

if grep -RInE '(OpenCode|OpenClaw|AskUserQuestion|WebSearch|webReader|\.opencode|opencode|\.claude|CLAUDE\.md|settings-hooks\.json|target_cli: claude-code|npx skills add|\b(haiku|sonnet|opus)\b)' \
  "$SKILL_FILE" "$UPGRADING_FILE" "$AGENT_TEMPLATES" "$CODEX_DIR" >/tmp/story-setup-contamination.$$ 2>/dev/null; then
  cat /tmp/story-setup-contamination.$$ >&2
  rm -f /tmp/story-setup-contamination.$$
  fail "old-runtime contamination detected in story-setup surface"
fi
rm -f /tmp/story-setup-contamination.$$
echo "  OK no old-runtime contamination"

echo ""
echo "OK: story-setup deployment contract is Codex-safe"
