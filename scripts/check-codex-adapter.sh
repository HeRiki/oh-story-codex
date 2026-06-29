#!/usr/bin/env bash
# check-codex-adapter.sh — deterministic checks for this Codex plugin port.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_file() { [ -f "$1" ] || fail "required file missing: $1"; }
assert_dir() { [ -d "$1" ] || fail "required directory missing: $1"; }
assert_grep() { grep -Eq "$1" "$2" || fail "$3 ($2)"; }

cd "$REPO_ROOT"

PYBIN=""
for candidate in python3 python py; do
  if "$candidate" -c 'import sys; raise SystemExit(sys.version_info < (3, 10))' >/dev/null 2>&1; then
    PYBIN="$candidate"
    break
  fi
done
[ -n "$PYBIN" ] || fail "Python 3.10+ is required for Codex adapter checks"

echo "Codex adapter check"
echo "==================="
echo "Repo: $REPO_ROOT"

PLUGIN_JSON=".codex-plugin/plugin.json"
ROOT_HOOKS="hooks/hooks.json"
ROOT_HOOK_SCRIPT="hooks/story-lifecycle-hook.cjs"
CODEX_DIR="skills/story-setup/references/codex"
CODEX_HOOK_JSON="$CODEX_DIR/hooks/hooks.json"
CODEX_HOOK_PY="$CODEX_DIR/hooks/story_codex_hook.py"

assert_file "$PLUGIN_JSON"
assert_file "$ROOT_HOOKS"
assert_file "$ROOT_HOOK_SCRIPT"
assert_file "$CODEX_DIR/AGENTS.md.tmpl"
assert_file "$CODEX_HOOK_JSON"
assert_file "$CODEX_HOOK_PY"
assert_dir "$CODEX_DIR/agents"
assert_file "scripts/generate-codex-agents.py"

node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" "$PLUGIN_JSON" >/dev/null
node -e "JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'))" "$ROOT_HOOKS" >/dev/null
node --check "$ROOT_HOOK_SCRIPT" >/dev/null
"$PYBIN" -m json.tool "$CODEX_HOOK_JSON" >/dev/null
"$PYBIN" - <<'PY'
from pathlib import Path
for name in (
    'scripts/generate-codex-agents.py',
    'skills/story-setup/references/codex/hooks/story_codex_hook.py',
):
    compile(Path(name).read_text(encoding='utf-8'), name, 'exec')
PY
echo "  OK JSON/JS/Python syntax"

assert_grep '"skills"[[:space:]]*:[[:space:]]*"./skills/"' "$PLUGIN_JSON" "plugin manifest must expose ./skills"
assert_grep '"hooks"[[:space:]]*:[[:space:]]*"./hooks/hooks.json"' "$PLUGIN_JSON" "plugin manifest must load root hooks"
assert_grep 'story-lifecycle-hook\.cjs' "$ROOT_HOOKS" "root hook manifest must invoke story-lifecycle-hook.cjs"
echo "  OK Codex plugin manifest"

assert_grep 'sys\.stdin\.buffer\.read' "$CODEX_HOOK_PY" "project hook must read stdin as UTF-8 bytes"
assert_grep 'sys\.stdout\.buffer\.write' "$CODEX_HOOK_PY" "project hook must write stdout as UTF-8 bytes"
if grep -qE 'sys\.stdin\.read\(\)|sys\.stdout\.write\(' "$CODEX_HOOK_PY"; then
  fail "project hook must not use locale text-mode stdin/stdout"
fi
if grep -nE '\.read_text\(' "$CODEX_HOOK_PY" | grep -qv 'encoding='; then
  fail "every project hook read_text() must pass encoding='utf-8'"
fi
assert_grep 'def prose_net_findings' "$CODEX_HOOK_PY" "project hook must carry the light prose net"
assert_grep 'def find_changed_prose_files' "$CODEX_HOOK_PY" "project hook must sweep git-changed prose on Stop"
assert_grep 'def continuity_findings' "$CODEX_HOOK_PY" "project hook must carry the continuity backstop"
echo "  OK project hook safety"

assert_grep 'for PYBIN in python3 python py' "$CODEX_HOOK_JSON" "project hook launcher must probe Python interpreter"
assert_grep 'sys\.version_info.*3, 10' "$CODEX_HOOK_JSON" "project hook launcher must reject Python versions older than 3.10"
assert_grep 'CODEX_PROJECT_DIR.*SEARCH_DIR' "$CODEX_HOOK_JSON" "project hook launcher must resolve project root without requiring git"
if grep -q 'git rev-parse' "$CODEX_HOOK_JSON"; then
  fail "project hook launcher must not require git before starting story_codex_hook.py"
fi
assert_grep '\.codex/hooks/story_codex_hook\.py' "$CODEX_HOOK_JSON" "project hook launcher must point at .codex/hooks"

"$PYBIN" - "$CODEX_HOOK_JSON" "$CODEX_HOOK_PY" <<'PY'
import json, sys
from pathlib import Path
hooks = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["hooks"]
all_hooks = [h for arr in hooks.values() for blk in arr for h in blk["hooks"]]
assert all_hooks, "no launcher commands found"
for h in all_hooks:
    c = h["command"]
    assert '[ -f "$HOOK" ] || exit 0' in c, f"launcher missing no-op guard: {c[:80]}"
    assert 'CODEX_PROJECT_DIR="$PROJECT_ROOT" "$PYBIN" "$HOOK"' in c, f"launcher must propagate root: {c[:80]}"
    w = h.get("commandWindows")
    assert w, f"hook missing commandWindows: {c[:60]}"
    assert "story_codex_hook.py" in w, f"commandWindows must invoke the hook: {w}"
    assert "CODEX_PROJECT_DIR" in w and "Path.cwd" in w, f"commandWindows must resolve/pass project root: {w}"
    for py_name in ("python3 -c", "python -c", "py -c"):
        assert py_name in w, f"commandWindows must probe {py_name}: {w}"
    for posixism in ("${", "$(", "[ -f", "for PYBIN", "for %", "; do ", "&& break"):
        assert posixism not in w, f"commandWindows must be cmd.exe-safe: {w}"
hook_py = Path(sys.argv[2]).read_text(encoding="utf-8")
assert "Path(__file__)" in hook_py and "_deployed_root_from_file" in hook_py, \
    "story_codex_hook.py must self-locate the project root from __file__"
PY
echo "  OK project hook launchers"

"$PYBIN" scripts/generate-codex-agents.py --dest "$TMP_DIR/agents" >/dev/null
diff -qr "$TMP_DIR/agents" "$CODEX_DIR/agents" >/dev/null \
  || fail "generated Codex agents are stale; run scripts/generate-codex-agents.py"

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
read_only = {'chapter-extractor', 'consistency-checker', 'story-explorer'}
legacy = "subagent" + "_type"
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

for path in sorted(Path('skills/story-setup/references/codex/agents').glob('*.toml')):
    data = read_agent(path)
    for key in ('name', 'description', 'developer_instructions'):
        assert data.get(key), f'{path}: missing {key}'
    name = data['name']
    instructions = data['developer_instructions']
    assert path.name == f'{name}.toml', f'{path}: filename/name mismatch'
    assert '.codex/skills/story-setup/references/agent-references/' in instructions
    assert '.codex/story-agent-references/' in instructions
    assert 'agent_type' in instructions, f'{path}: missing Codex agent_type guidance'
    assert legacy not in instructions, f'{path}: leaked legacy agent field wording'
    assert 'unknown agent_type' in instructions, f'{path}: missing runtime fallback guidance'
    if name in read_only:
        assert data.get('sandbox_mode') == 'read-only', f'{path}: expected read-only sandbox'
    found.add(name)
assert found == expected, found
PY
echo "  OK Codex custom-agent TOML"

assert_grep '\$story-setup|\$story-long-write|/skills' "$CODEX_DIR/AGENTS.md.tmpl" "Codex AGENTS template must mention skill invocation"
assert_grep '\.codex/agents/\*\.toml' "$CODEX_DIR/AGENTS.md.tmpl" "Codex AGENTS template must mention custom agent location"
assert_grep '\.codex/hooks\.json' "$CODEX_DIR/AGENTS.md.tmpl" "Codex AGENTS template must mention hooks location"
assert_grep 'references/codex' skills/story-setup/SKILL.md "story-setup must document Codex references"
assert_grep '\.codex/agents|\.codex/hooks\.json' skills/story-review/SKILL.md "story-review must check Codex agents"
echo "  OK Codex docs/instruction anchors"

echo ""
echo "OK: Codex adapter checks passed"
