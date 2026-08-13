#!/bin/bash
# check-hook-regex-sync.sh — 行为级校验 Codex 生命周期 hook 的 schema 4 追踪提示。
#
# SessionStart 只从 _tracking-state.json 单一权威读取状态；旧扁平 Markdown
# 即使缺失或冲突也不能影响判断，更不能阻断 tracking_commit.py 的合法事务。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

HOOK_FILE="$REPO_ROOT/hooks/story-lifecycle-hook.cjs"
TRACKING_TOOL="$REPO_ROOT/skills/story-long-write/scripts/tracking_commit.py"

for file in "$HOOK_FILE" "$TRACKING_TOOL"; do
  if [ ! -f "$file" ]; then
    echo "FAIL: required file not found: $file"
    exit 1
  fi
done

STATUS_ENUM=$(grep -E '^FORESHADOW_STATUSES = ' "$TRACKING_TOOL" | head -1 | grep -oE '"[^"]+"' | tr -d '"' | paste -sd/ - || true)
if [ -z "$STATUS_ENUM" ]; then
  echo "FAIL: No foreshadow status enum found in protocol file"
  exit 1
fi

echo "Protocol defines status values: $STATUS_ENUM"

TMP_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$TMP_DIR"
  rm -rf "$REPO_ROOT/.tmp-oh-story-msys-$$"
}
trap cleanup EXIT

setup_fixture() {
  local name="$1"
  local status="${2:-}"
  local root="$TMP_DIR/$name"
  mkdir -p "$root/book/追踪" "$root/book/正文" "$root/book/设定" "$root/book/大纲"
  touch "$root/.story-deployed"
  cat > "$root/book/追踪/上下文.md" <<'CTX'
# 写作进度
## 当前位置
- 章: 第1章
CTX
  if [ -n "$status" ]; then
    foreshadow="\"F001\":{\"status\":\"$status\"}"
  else
    foreshadow=""
  fi
  printf '{"schema_version":4,"book_title":"测试","last_committed_chapter":1,"imported_through_chapter":1,"state_revision":0,"context":{},"characters":{},"foreshadow":{%s},"timeline":{}}\n' "$foreshadow" > "$root/book/追踪/_tracking-state.json"
  printf '%s' "$root"
}

run_hook() {
  local root="$1"
  local node_root="$root"
  if command -v cygpath >/dev/null 2>&1; then
    node_root="$(cygpath -m "$root")"
  fi
  printf '{"cwd":"%s","hook_event_name":"SessionStart"}' "$node_root" | node "$HOOK_FILE" session-start
}

assert_no_foreshadow_warn() {
  local case_name="$1"
  local body="$2"
  local root output
  root=$(setup_fixture "$case_name" "$body")
  output=$(run_hook "$root" || true)
  if echo "$output" | grep -q '过期或异常伏笔\|未关闭伏笔'; then
    echo "FAIL: $case_name should not emit foreshadow warning"
    echo "Output:"
    echo "$output"
    exit 1
  fi
  echo "  OK no warn: $case_name"
}

assert_foreshadow_warn() {
  local case_name="$1"
  local body="$2"
  local root output
  root=$(setup_fixture "$case_name" "$body")
  output=$(run_hook "$root" || true)
  if ! echo "$output" | grep -q '过期或异常伏笔'; then
    echo "FAIL: $case_name should emit overdue/abnormal foreshadow warning"
    echo "Output:"
    echo "$output"
    exit 1
  fi
  echo "  OK warn: $case_name"
}

assert_no_foreshadow_warn "empty-state" ""
assert_no_foreshadow_warn "normal-open-planted" "已埋"
assert_no_foreshadow_warn "closed-recovered" "已回收"
assert_no_foreshadow_warn "abandoned" "放弃"
assert_foreshadow_warn "overdue" "已过期"
assert_foreshadow_warn "invalid-unplanted" "未埋"
assert_foreshadow_warn "unknown-status" "状态损坏"

authority_root=$(setup_fixture "state-authority" "已埋")
printf '| F999 | 旧文件冲突 | 已过期 |\n' > "$authority_root/book/追踪/伏笔.md"
printf '# 旧扁平时间线\n' > "$authority_root/book/追踪/时间线.md"
authority_output=$(run_hook "$authority_root" || true)
if echo "$authority_output" | grep -q '过期或异常伏笔\|未发现 `追踪/时间线.md`'; then
  echo "FAIL: legacy flat Markdown must not override schema 4 state"
  echo "$authority_output"
  exit 1
fi
echo "  OK authority: schema 4 state overrides legacy flat Markdown"

missing_state_root="$TMP_DIR/missing-state"
mkdir -p "$missing_state_root/book/追踪" "$missing_state_root/book/正文" "$missing_state_root/book/设定" "$missing_state_root/book/大纲"
touch "$missing_state_root/.story-deployed" "$missing_state_root/book/追踪/上下文.md"
missing_output=$(run_hook "$missing_state_root")
echo "$missing_output" | grep -q '_tracking-state.json' || { echo "FAIL: missing state must emit migration guidance"; exit 1; }
echo "  OK hint: missing state reports migration without blocking"

active_root="$TMP_DIR/active-book"
for book in A旧书 B活跃书; do
  mkdir -p "$active_root/$book/追踪" "$active_root/$book/正文" "$active_root/$book/设定" "$active_root/$book/大纲"
done
touch "$active_root/.story-deployed"
printf 'B活跃书\n' > "$active_root/.active-book"
printf '# A旧书上下文，不应出现\n' > "$active_root/A旧书/追踪/上下文.md"
printf '# B活跃书上下文，应当出现\n' > "$active_root/B活跃书/追踪/上下文.md"
printf '{"schema_version":4,"book_title":"A旧书","last_committed_chapter":1,"imported_through_chapter":1,"state_revision":0,"context":{},"characters":{},"foreshadow":{"F001":{"status":"已过期"}},"timeline":{}}\n' > "$active_root/A旧书/追踪/_tracking-state.json"
printf '{"schema_version":4,"book_title":"B活跃书","last_committed_chapter":1,"imported_through_chapter":1,"state_revision":0,"context":{},"characters":{},"foreshadow":{},"timeline":{}}\n' > "$active_root/B活跃书/追踪/_tracking-state.json"
active_output=$(run_hook "$active_root")
echo "$active_output" | grep -q '活跃书目：B活跃书' || { echo "FAIL: SessionStart did not select .active-book"; echo "$active_output"; exit 1; }
echo "$active_output" | grep -q 'B活跃书上下文，应当出现' || { echo "FAIL: SessionStart did not read active-book context"; echo "$active_output"; exit 1; }
if echo "$active_output" | grep -q 'A旧书上下文\|过期或异常伏笔'; then
  echo "FAIL: inactive book leaked into SessionStart context"
  echo "$active_output"
  exit 1
fi
node_active_root="$active_root"
if command -v cygpath >/dev/null 2>&1; then
  node_active_root="$(cygpath -m "$active_root")"
fi
printf '{"cwd":"%s","hook_event_name":"Stop"}' "$node_active_root" \
  | STORY_SESSION_LOG=1 node "$HOOK_FILE" stop
test -f "$active_root/B活跃书/追踪/session-log.txt" || { echo "FAIL: session log was not written to active book"; exit 1; }
test ! -e "$active_root/A旧书/追踪/session-log.txt" || { echo "FAIL: session log leaked into inactive book"; exit 1; }
echo "  OK active-book: context, gap scan, and session log stay within B活跃书"

printf '../outside\n' > "$active_root/.active-book"
escape_output=$(run_hook "$active_root")
if echo "$escape_output" | grep -q '活跃书目：A旧书\|活跃书目：B活跃书\|A旧书上下文\|B活跃书上下文'; then
  echo "FAIL: invalid .active-book must not silently select another book"
  echo "$escape_output"
  exit 1
fi
echo "$escape_output" | grep -q 'active-book.*无效' || { echo "FAIL: invalid .active-book must report a diagnostic"; echo "$escape_output"; exit 1; }
echo "  OK containment: invalid .active-book is diagnosed without switching books"

if grep -q '未关闭伏笔' "$HOOK_FILE"; then
  echo "FAIL: old open-foreshadow warning wording is still present in Codex hook"
  exit 1
fi

for state in $(echo "$STATUS_ENUM" | tr '/' ' '); do
  if ! grep -qF "$state" "$HOOK_FILE"; then
    echo "FAIL: status not documented in hook/protocol semantics: $state"
    exit 1
  fi
done

setup_prose_guard_fixture() {
  local name="$1"
  local root="$TMP_DIR/$name"
  mkdir -p "$root/长篇/正文" "$root/长篇/大纲" "$root/短篇"
  touch "$root/.story-deployed"
  touch "$root/短篇/设定.md"
  printf '%s' "$root"
}

run_pretool_write() {
  local root="$1"
  local target="$2"
  local node_root="$root"
  if command -v cygpath >/dev/null 2>&1; then
    node_root="$(cygpath -m "$root")"
  fi
  printf '{"cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"%s"}}' "$node_root" "$target" \
    | node "$HOOK_FILE" pre-tool-use >/tmp/oh-story-hook-guard.out 2>/tmp/oh-story-hook-guard.err
}

run_pretool_patch_add() {
  local root="$1"
  local target="$2"
  local node_root="$root"
  if command -v cygpath >/dev/null 2>&1; then
    node_root="$(cygpath -m "$root")"
  fi
  printf '{"cwd":"%s","hook_event_name":"PreToolUse","tool_name":"functions.apply_patch","tool_input":{"patch":"*** Begin Patch\\n*** Add File: %s\\n+正文\\n*** End Patch\\n"}}' "$node_root" "$target" \
    | node "$HOOK_FILE" pre-tool-use >/tmp/oh-story-hook-guard.out 2>/tmp/oh-story-hook-guard.err
}

run_pretool_patch_move() {
  local root="$1"
  local source="$2"
  local target="$3"
  local node_root="$root"
  if command -v cygpath >/dev/null 2>&1; then
    node_root="$(cygpath -m "$root")"
  fi
  printf '{"cwd":"%s","hook_event_name":"PreToolUse","tool_name":"functions.apply_patch","tool_input":{"patch":"*** Begin Patch\\n*** Update File: %s\\n*** Move to: %s\\n@@\\n 正文\\n*** End Patch\\n"}}' "$node_root" "$source" "$target" \
    | node "$HOOK_FILE" pre-tool-use >/tmp/oh-story-hook-guard.out 2>/tmp/oh-story-hook-guard.err
}

guard_root="$(setup_prose_guard_fixture prose-guard)"
guard_ec=0
run_pretool_write "$guard_root" "长篇/正文/第1章_开篇.md" || guard_ec=$?
if [ "$guard_ec" -ne 2 ]; then
  echo "FAIL: prose guard should block first long-form chapter without outline, got exit $guard_ec"
  cat /tmp/oh-story-hook-guard.out /tmp/oh-story-hook-guard.err
  exit 1
fi
echo "  OK block: long-form prose without outline"

touch "$guard_root/长篇/大纲/细纲_第1章.md"
guard_ec=0
run_pretool_write "$guard_root" "长篇/正文/第1章_开篇.md" || guard_ec=$?
if [ "$guard_ec" -ne 0 ]; then
  echo "FAIL: prose guard should allow long-form chapter with outline, got exit $guard_ec"
  cat /tmp/oh-story-hook-guard.out /tmp/oh-story-hook-guard.err
  exit 1
fi
echo "  OK allow: long-form prose with outline"

short_ec=0
run_pretool_write "$guard_root" "短篇/正文.md" || short_ec=$?
if [ "$short_ec" -ne 2 ]; then
  echo "FAIL: prose guard should block first short-form prose without section outline, got exit $short_ec"
  cat /tmp/oh-story-hook-guard.out /tmp/oh-story-hook-guard.err
  exit 1
fi
echo "  OK block: short-form prose without outline"

touch "$guard_root/短篇/正文.md"
short_ec=0
run_pretool_write "$guard_root" "短篇/正文.md" || short_ec=$?
if [ "$short_ec" -ne 0 ]; then
  echo "FAIL: prose guard should allow existing prose file revisions, got exit $short_ec"
  cat /tmp/oh-story-hook-guard.out /tmp/oh-story-hook-guard.err
  exit 1
fi
echo "  OK allow: existing prose revision"

patch_guard_root="$(setup_prose_guard_fixture prose-guard-patch)"
patch_ec=0
run_pretool_patch_add "$patch_guard_root" "长篇/正文/第2章_开篇.md" || patch_ec=$?
if [ "$patch_ec" -ne 2 ]; then
  echo "FAIL: prose guard should block apply_patch add-file without outline, got exit $patch_ec"
  cat /tmp/oh-story-hook-guard.out /tmp/oh-story-hook-guard.err
  exit 1
fi
echo "  OK block: apply_patch add-file prose without outline"

touch "$patch_guard_root/长篇/大纲/细纲_第2章.md"
patch_ec=0
run_pretool_patch_add "$patch_guard_root" "长篇/正文/第2章_开篇.md" || patch_ec=$?
if [ "$patch_ec" -ne 0 ]; then
  echo "FAIL: prose guard should allow apply_patch add-file with outline, got exit $patch_ec"
  cat /tmp/oh-story-hook-guard.out /tmp/oh-story-hook-guard.err
  exit 1
fi
echo "  OK allow: apply_patch add-file prose with outline"

move_guard_root="$(setup_prose_guard_fixture prose-guard-move)"
mkdir -p "$move_guard_root/草稿"
touch "$move_guard_root/草稿/第3章.md"
move_ec=0
run_pretool_patch_move "$move_guard_root" "草稿/第3章.md" "长篇/正文/第3章_开篇.md" || move_ec=$?
if [ "$move_ec" -ne 2 ]; then
  echo "FAIL: prose guard should block apply_patch move-to prose without outline, got exit $move_ec"
  cat /tmp/oh-story-hook-guard.out /tmp/oh-story-hook-guard.err
  exit 1
fi
echo "  OK block: apply_patch move-to prose without outline"

touch "$move_guard_root/长篇/大纲/细纲_第3章.md"
move_ec=0
run_pretool_patch_move "$move_guard_root" "草稿/第3章.md" "长篇/正文/第3章_开篇.md" || move_ec=$?
if [ "$move_ec" -ne 0 ]; then
  echo "FAIL: prose guard should allow apply_patch move-to prose with outline, got exit $move_ec"
  cat /tmp/oh-story-hook-guard.out /tmp/oh-story-hook-guard.err
  exit 1
fi
echo "  OK allow: apply_patch move-to prose with outline"

if command -v cygpath >/dev/null 2>&1; then
  msys_guard_root="$REPO_ROOT/.tmp-oh-story-msys-$$/prose-guard-msys"
  mkdir -p "$msys_guard_root/长篇/正文" "$msys_guard_root/长篇/大纲" "$msys_guard_root/短篇"
  touch "$msys_guard_root/.story-deployed"
  touch "$msys_guard_root/短篇/设定.md"
  msys_node_root="$(cygpath -m "$msys_guard_root")"
  msys_cwd="$(cygpath -u "$msys_node_root")"
  case "$msys_cwd" in
    /[A-Za-z]/*)
      msys_ec=0
      printf '{"cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"长篇/正文/第4章_开篇.md"}}' "$msys_cwd" \
        | node "$HOOK_FILE" pre-tool-use >/tmp/oh-story-hook-guard.out 2>/tmp/oh-story-hook-guard.err || msys_ec=$?
      if [ "$msys_ec" -ne 2 ]; then
        echo "FAIL: prose guard should resolve MSYS-style cwd and block missing outline, got exit $msys_ec"
        cat /tmp/oh-story-hook-guard.out /tmp/oh-story-hook-guard.err
        exit 1
      fi
      echo "  OK block: MSYS-style cwd resolves story root"

      touch "$msys_guard_root/长篇/大纲/细纲_第4章.md"
      msys_abs_target="$(cygpath -u "$(cygpath -m "$msys_guard_root/长篇/正文/第4章_开篇.md")")"
      msys_ec=0
      run_pretool_write "$msys_guard_root" "$msys_abs_target" || msys_ec=$?
      if [ "$msys_ec" -ne 0 ]; then
        echo "FAIL: prose guard should resolve MSYS-style absolute target with outline, got exit $msys_ec"
        cat /tmp/oh-story-hook-guard.out /tmp/oh-story-hook-guard.err
        exit 1
      fi
      echo "  OK allow: MSYS-style absolute target with outline"
      ;;
    *)
      echo "  SKIP: cygpath did not produce MSYS drive path for cwd ($msys_cwd)"
      ;;
  esac
fi

echo ""
echo "OK: Codex hook foreshadow and prose-outline guard behavior is valid"
