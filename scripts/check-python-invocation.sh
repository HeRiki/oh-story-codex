#!/bin/bash
# check-python-invocation.sh — 守卫：技能文档里禁止裸调 `python3`
#
# Windows 上 python.org 安装后 `python3` 可能落到 Microsoft Store 占位程序、以
# exit 49 静默失败。所有调用必须先按 python3 -> python -> py 探测可用解释器：
#   for PYBIN in python3 python py; do "$PYBIN" -c "" 2>/dev/null && break; done
#   "$PYBIN" -c "..."
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "Error: not in a git repository"
  exit 1
fi

# 裸调用形态：python3 + 空白 + 任意非空白参数（覆盖 -c / -m / << / 脚本路径 / 引号）
PATTERN='python3[[:space:]]+[^[:space:]]'
# 探测列表 `... in python3 python py ...` 是允许写法。
ALLOW='python3 python py'

echo "Python Invocation Guard"
echo "======================="

# 只扫 skills/，CI/scripts 自身允许按测试需要构造 python3 stub。
hits="$(grep -rnE "$PATTERN" "$REPO_ROOT/skills" 2>/dev/null | grep -vF "$ALLOW" || true)"

if [ -n "$hits" ]; then
  echo "FAIL: 发现裸调 python3（Windows 上可能 exit 49）："
  echo "$hits"
  echo
  echo "改用解释器探测形态："
  echo '  for PYBIN in python3 python py; do "$PYBIN" -c "" 2>/dev/null && break; done'
  echo '  "$PYBIN" -c "..."'
  exit 1
fi

echo "OK: 未发现裸调 python3"
