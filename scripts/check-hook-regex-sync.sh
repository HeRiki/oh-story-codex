#!/bin/bash
# check-hook-regex-sync.sh — 校验 Codex 生命周期 hook 中的伏笔状态匹配
# 是否覆盖 artifact-protocols.md 中定义的所有“未关闭”伏笔状态。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

HOOK_FILE="$REPO_ROOT/hooks/story-lifecycle-hook.cjs"
PROTOCOL_FILE="$REPO_ROOT/skills/story-long-write/references/artifact-protocols.md"

if [ ! -f "$HOOK_FILE" ]; then
  echo "FAIL: hook file not found: $HOOK_FILE"
  exit 1
fi
if [ ! -f "$PROTOCOL_FILE" ]; then
  echo "FAIL: protocol file not found: $PROTOCOL_FILE"
  exit 1
fi

STATUS_ENUM=$(grep -oE '状态\{[^}]+\}' "$PROTOCOL_FILE" 2>/dev/null | head -1 | sed 's/状态{//;s/}//' || true)
if [ -z "$STATUS_ENUM" ]; then
  echo "WARN: No foreshadow status enum found in protocol file"
  exit 0
fi

echo "Protocol defines status values: $STATUS_ENUM"

CLOSED_STATES="已回收"
FAIL=""

while IFS= read -r state; do
  [ -z "$state" ] && continue

  is_closed=false
  for closed in $CLOSED_STATES; do
    if [ "$state" = "$closed" ]; then
      is_closed=true
      break
    fi
  done
  if [ "$is_closed" = true ]; then
    echo "  SKIP (closed): $state"
    continue
  fi

  if grep -qF "\"$state\"" "$HOOK_FILE" 2>/dev/null; then
    echo "  OK:   $state -> matched in Codex hook"
  else
    echo "  FAIL: $state -> NOT matched in Codex hook"
    FAIL="$FAIL $state"
  fi
done < <(echo "$STATUS_ENUM" | tr '/' '\n')

if [ -n "$FAIL" ]; then
  echo ""
  echo "FAIL: story-lifecycle-hook.cjs does not match the following open foreshadow states:"
  for f in $FAIL; do
    echo "  - $f"
  done
  exit 1
fi

echo ""
echo "OK: Codex hook covers all open foreshadow states from artifact-protocols.md"
