#!/bin/bash
# test-charcount-portable.sh — 验证「跨平台字符统计」命令在三大平台 + Windows
# Microsoft Store 占位程序场景下都能正确数出中文字符数。
set -euo pipefail

STUB=0
[ "${1:-}" = "--stub" ] && STUB=1

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

BOOK_DIR="$WORK/小说项目/第一卷"
mkdir -p "$BOOK_DIR"
# 12 个码位：中文字数测试(6) + ABC(3) + 123(3)，无结尾换行。
printf '%s' '中文字数测试ABC123' > "$BOOK_DIR/正文.md"
EXPECT=12

if [ "$STUB" -eq 1 ]; then
  FAKEBIN="$WORK/fakebin"
  mkdir -p "$FAKEBIN"
  printf '#!/bin/sh\nexit 49\n' > "$FAKEBIN/python3"
  chmod +x "$FAKEBIN/python3"
  PATH="$FAKEBIN:$PATH"
  export PATH
  echo "[stub] python3 现在固定 exit 49（模拟 Microsoft Store 占位程序）"
fi

# 与技能文档保持一致：先探测解释器，再在目标目录内用相对路径统计。
for PYBIN in python3 python py; do "$PYBIN" -c "" 2>/dev/null && break; done
GOT="$(cd "$BOOK_DIR" && "$PYBIN" -c "from pathlib import Path; print(len(Path('正文.md').read_text(encoding='utf-8')))")"

echo "selected interpreter: $PYBIN"
echo "char count: $GOT (expect $EXPECT)"

fail=0
if [ "$GOT" != "$EXPECT" ]; then
  echo "FAIL: 字符数不符（中文路径或解释器问题）"
  fail=1
fi
if [ "$STUB" -eq 1 ] && [ "$PYBIN" = "python3" ]; then
  echo "FAIL: stub 模式下仍选中了坏掉的 python3，回退链没生效"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS"
fi
exit "$fail"
