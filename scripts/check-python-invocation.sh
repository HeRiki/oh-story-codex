#!/bin/bash
# check-python-invocation.sh — 守卫：技能文档里禁止裸调 `python3`
#
# Windows 上 python.org 安装后 `python3` 会落到 Microsoft Store 占位程序、以 exit 49
# 静默失败（见 issue #121）。所有调用必须先按 python3 -> python -> py 探测可用解释器：
#   for PYBIN in python3 python py; do "$PYBIN" -c "" 2>/dev/null && break; done
#   "$PYBIN" -c "..."
#
# 本守卫拦截一切「裸调用」形态：python3 紧跟空白再接任意参数（-c / -m / <<  /
# 脚本路径 / 引号等）。探测列表 `python3 python py` 与说明文字（python3 后紧跟
# 反斜杠引号、破折号、箭头等，无空白）不受影响。cmd.exe 的 commandWindows 不支持
# POSIX for-loop，允许 `python -c ... || py -c ... || python3 -c ... || exit /b 0`
# 这种显式回退链（python3 放最后，避开 Windows Store alias 返回 0 的问题）。
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "Error: not in a git repository"
  exit 1
fi

# 裸调用形态：python3 + 空白 + 任意非空白参数（覆盖 -c / -m / << / 脚本路径 / 引号）
PATTERN='python3[[:space:]]+[^[:space:]]'
# 探测列表 `... in python3 python py ...` 是允许写法，从命中里剔除（兼容 PYBIN/c 等变量名）
ALLOW='python3 python py'

echo "Python Invocation Guard"
echo "======================="

# skills/ 文档（CI scripts 自身允许用任意写法，不扫）
hits="$(
  grep -rnE "$PATTERN" "$REPO_ROOT/skills" 2>/dev/null \
    | awk -v allow="$ALLOW" '
        {
          rest = $0
          if (index(rest, allow) > 0) next
          gsub(/python -c [^|]*\|\| py -c [^|]*\|\| python3 -c [^|]*\|\| exit \/b 0/, "", rest)
          if (rest ~ /python3[[:space:]]+[^[:space:]]/) print $0
        }
      ' \
    || true
)"

if [ -n "$hits" ]; then
  echo "FAIL: 发现裸调 python3（Windows 上会 exit 49）："
  echo "$hits"
  echo
  echo "改用解释器探测形态："
  echo '  for PYBIN in python3 python py; do "$PYBIN" -c "" 2>/dev/null && break; done'
  echo '  "$PYBIN" -c "..."'
  exit 1
fi

echo "OK: 未发现裸调 python3"
echo

# 第二道守卫：Codex 项目 hook 不准用文本模式 stdout 输出（print(/sys.stdout.write）。
# Windows 中文系统 python stdout 默认 cp936，文本模式会把中文路径编成 GBK。要把值交给
# Codex hook stdout 必须直写 UTF-8 字节：sys.stdout.buffer.write(value.encode("utf-8"))。
HOOK_PY="$REPO_ROOT/skills/story-setup/references/codex/hooks/story_codex_hook.py"
TEXT_STDOUT='print\(|sys\.stdout\.write\('

echo "Hook stdout-encoding Guard"
echo "=========================="
if [ -f "$HOOK_PY" ]; then
  enc_hits="$(grep -nE "$TEXT_STDOUT" "$HOOK_PY" 2>/dev/null || true)"
else
  enc_hits=""
fi

if [ -n "$enc_hits" ]; then
  echo "FAIL: hook 内嵌 python 用了文本模式 stdout 输出（Windows 中文系统会编成 GBK，守卫静默失效）："
  echo "$enc_hits"
  echo
  echo "把要交给 shell 的值直写 UTF-8 字节："
  echo '  sys.stdout.buffer.write(value.encode("utf-8"))'
  exit 1
fi

echo "OK: hook 内嵌 python 未发现文本模式 stdout 输出"
