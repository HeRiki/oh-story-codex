#!/bin/bash
# check-hook-regex-sync.sh — 行为级校验 Codex 生命周期 hook 的伏笔提示。
#
# SessionStart 只提示已过期或异常伏笔，不能把未埋/已埋这类正常开放
# 状态当成缺口，否则会诱发日更流程全量伏笔审计和上下文膨胀。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

HOOK_FILE="$REPO_ROOT/hooks/story-lifecycle-hook.cjs"
PROTOCOL_FILE="$REPO_ROOT/skills/story-long-write/references/artifact-protocols.md"

for file in "$HOOK_FILE" "$PROTOCOL_FILE"; do
  if [ ! -f "$file" ]; then
    echo "FAIL: required file not found: $file"
    exit 1
  fi
done

STATUS_ENUM=$(grep -oE '状态\{[^}]+\}' "$PROTOCOL_FILE" 2>/dev/null | head -1 | sed 's/状态{//;s/}//' || true)
if [ -z "$STATUS_ENUM" ]; then
  echo "FAIL: No foreshadow status enum found in protocol file"
  exit 1
fi

echo "Protocol defines status values: $STATUS_ENUM"

TMP_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

setup_fixture() {
  local name="$1"
  local foreshadow_body="$2"
  local root="$TMP_DIR/$name"
  mkdir -p "$root/book/追踪" "$root/book/正文" "$root/book/设定" "$root/book/大纲"
  touch "$root/.story-deployed"
  cat > "$root/book/追踪/上下文.md" <<'CTX'
# 写作进度
## 当前位置
- 章: 第1章
CTX
  touch "$root/book/追踪/时间线.md"
  cat > "$root/book/追踪/伏笔.md" <<EOF_FORESHADOW
# 伏笔追踪

## 伏笔状态表

| ID | 伏笔内容 | 埋设章节 | 预计回收章节 | 状态{未埋/已埋/已回收/已过期} | 重要度{高/中/低} |
|----|---------|---------|-------------|-----------------------------|----------------|
$foreshadow_body
EOF_FORESHADOW
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

assert_no_foreshadow_warn "header-only" ""

plain_header_root="$TMP_DIR/plain-header"
mkdir -p "$plain_header_root/book/追踪" "$plain_header_root/book/正文" "$plain_header_root/book/设定" "$plain_header_root/book/大纲"
touch "$plain_header_root/.story-deployed"
cat > "$plain_header_root/book/追踪/上下文.md" <<'CTX'
# 写作进度
## 当前位置
- 章: 第1章
CTX
touch "$plain_header_root/book/追踪/时间线.md"
cat > "$plain_header_root/book/追踪/伏笔.md" <<'EOF_PLAIN_HEADER'
# 伏笔追踪

| ID | 名称 | 埋下 | 回收 | 状态 | 备注 |
|----|------|------|------|------|------|
| F001 | 玉佩 | 第1章 | 第20章 | 未埋 | ok |
EOF_PLAIN_HEADER
plain_header_output=$(run_hook "$plain_header_root" || true)
if echo "$plain_header_output" | grep -q '过期或异常伏笔\|未关闭伏笔'; then
  echo "FAIL: plain-header should not emit foreshadow warning"
  echo "Output:"
  echo "$plain_header_output"
  exit 1
fi
echo "  OK no warn: plain-header"

assert_no_foreshadow_warn "planned-unplanted" "| F001 | 计划后续埋设 | 第5章 | 第10章 | 未埋 | 中 |"
assert_no_foreshadow_warn "normal-open-planted" "| F002 | 正常开放伏笔 | 第1章 | 第20章 | 已埋 | 高 |"
assert_no_foreshadow_warn "closed-recovered" "| F003 | 已回收伏笔 | 第1章 | 第3章 | 已回收 | 低 |"
assert_foreshadow_warn "overdue" "| F004 | 过期伏笔 | 第1章 | 第2章 | 已过期 | 高 |"
assert_foreshadow_warn "unknown-status" "| F005 | 异常状态 | 第1章 | 第2章 | 状态损坏 | 高 |"

if grep -q '未关闭伏笔' "$HOOK_FILE"; then
  echo "FAIL: old open-foreshadow warning wording is still present in Codex hook"
  exit 1
fi

for state in $(echo "$STATUS_ENUM" | tr '/' ' '); do
  if ! grep -qF "$state" "$HOOK_FILE" && ! grep -qF "$state" "$PROTOCOL_FILE"; then
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

echo ""
echo "OK: Codex hook foreshadow and prose-outline guard behavior is valid"
