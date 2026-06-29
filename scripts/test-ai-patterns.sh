#!/bin/bash
# test-ai-patterns.sh — regression tests for the deterministic AI-pattern detector.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "Error: not in a git repository" >&2
  exit 1
fi

SCRIPTS=(
  "$REPO_ROOT/skills/story-deslop/scripts/check-ai-patterns.js"
  "$REPO_ROOT/skills/story-long-write/scripts/check-ai-patterns.js"
  "$REPO_ROOT/skills/story-review/scripts/check-ai-patterns.js"
  "$REPO_ROOT/skills/story-short-write/scripts/check-ai-patterns.js"
)
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

FIXTURE="$TMP_DIR/fixture.md"
OUT="$TMP_DIR/out.json"

run_detector() {
  local script="$1"
  shift
  node "$script" "$@"
}

for script in "${SCRIPTS[@]}"; do
  [ -f "$script" ] || { echo "FAIL: detector missing: $script" >&2; exit 1; }
done

cat > "$FIXTURE" <<'EOF'
---
title: 不是A，而是B
---
是不是这里不该报。
他不是冷漠，而是绝望。
她不是害怕，是累了。
他不是笨是太急。
他不是冷漠；是绝望。
它不是普通的粥！
是药。
它不是普通的粥
是药。
他不是冷漠. 而是绝望。
It was not a bug. It was a feature.
她不是不想走，也不是不敢走。
他不是讨厌你，只是累了。
他不是走了，可是没人知道。
他不是不愿意，于是答应了。
她不是生气，倒是有点担心。
他不是哭就是闹。
这事不是真的就是假的。
这不是你的东西，是吗？
他不是傻子。是吗？
他不是傻子，是吧。
不是这样，是嘛。
```
他不是冷漠，而是绝望。
```
~~~md
他不是普通表达，而是代码示例。
~~~
EOF

for SCRIPT in "${SCRIPTS[@]}"; do
set +e
run_detector "$SCRIPT" --json "$FIXTURE" > "$OUT"
status=$?
set -e

if [ "$status" -ne 1 ]; then
  echo "FAIL: expected detector to exit 1 for positive findings, got $status ($SCRIPT)" >&2
  cat "$OUT" >&2 || true
  exit 1
fi

node - "$OUT" <<'NODE'
const fs = require('fs');
const report = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const excerpts = report.findings.map((finding) => finding.excerpt);

// Genuine flips that MUST be detected: 而是 / “，是” / compact / “；是” / hard-stop + 是.
const expected = [
  '不是冷漠，而是绝望',
  '不是害怕，是累了',
  '不是笨是太急',
  '不是冷漠；是绝望',
  '不是普通的粥！ 是药',
  '不是普通的粥 是药',
  '不是冷漠. 而是绝望',
];

// Natural prose that MUST NOT be flagged: the trailing 是 of a conjunction
// (只是/可是/于是/倒是…) after a separator is not a positive copula (issue #166
// false-positive class). “是不是”/“也不是” second-negation must also stay silent.
const forbidden = [
  '只是累了',
  '可是没人知道',
  '于是答应了',
  '倒是有点担心',
  // either-or「不是A就是B / 也是B」与句尾反问「…，是吗 / 是吧 / 是嘛」不是否定后翻转。
  '哭就是',
  '真的就是',
  '是吗',
  '是吧',
  '是嘛',
];

if (report.findings.length !== expected.length) {
  throw new Error(`expected ${expected.length} findings, got ${report.findings.length}: ${JSON.stringify(excerpts)}`);
}

for (const excerpt of expected) {
  if (!excerpts.includes(excerpt)) {
    throw new Error(`missing expected excerpt: ${excerpt}; got ${JSON.stringify(excerpts)}`);
  }
}

for (const marker of forbidden) {
  if (excerpts.some((excerpt) => excerpt.includes(marker))) {
    throw new Error(`false positive: conjunction "${marker}" was flagged; got ${JSON.stringify(excerpts)}`);
  }
}
NODE
done

echo "AI pattern detector regression tests passed."

# --- 段落级检测：碎句号 / 长段落 / 破折号（issue #188） ---
FIXTURE2="$TMP_DIR/fixture-prose.md"
LONG_PARA="他沿着长廊一直往里走，"
i=0
while [ "$i" -lt 16 ]; do
  LONG_PARA="${LONG_PARA}走过一道又一道紧闭的木门，"
  i=$((i + 1))
done
LONG_PARA="${LONG_PARA}终于在尽头停下，盯着那点暗红看了很久。"
{
  # 6 句连续短叙述句 → 碎句号
  printf '%s\n' '他站起来。' '他走过去。' '门开了。' '风进来。' '他停住。' '心一沉。'
  # 6 句对话短句 → 必须不报碎句号（成片短句是对话/弹幕的正常形态）
  printf '%s\n' '“这真的没问题。”' '“一点也不难。”' '“我信你。”' '“你别紧张。”' '“好。”' '“嗯。”'
  # 破折号 → em-dash（按功能改写，不机械替换）
  printf '%s\n' '她借着月光看清了桌上那张纸的边角——那是一张旧纸。'
  # 单段超长 → long-paragraph
  printf '%s\n' "$LONG_PARA"
} > "$FIXTURE2"

for SCRIPT in "${SCRIPTS[@]}"; do
set +e
run_detector "$SCRIPT" --json "$FIXTURE2" > "$OUT"
status=$?
set -e
if [ "$status" -ne 1 ]; then
  echo "FAIL: expected prose detector to exit 1 for positive findings, got $status ($SCRIPT)" >&2
  cat "$OUT" >&2 || true
  exit 1
fi

node - "$OUT" <<'NODE'
const fs = require('fs');
const report = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const counts = report.findings.reduce((m, f) => ((m[f.type] = (m[f.type] || 0) + 1), m), {});

// Exactly one of each new prose type, nothing else. The 6 dialogue lines must NOT
// trip 碎句号 (成片短句是对话/弹幕的正常形态 — only narrative runs count).
if (report.findings.length !== 3) {
  throw new Error(`expected 3 prose findings, got ${report.findings.length}: ${JSON.stringify(report.findings.map((f) => `${f.type}@${f.line}`))}`);
}
for (const type of ['period-stutter', 'em-dash', 'long-paragraph']) {
  if (counts[type] !== 1) throw new Error(`expected exactly 1 ${type}, got ${counts[type] || 0}`);
}
// 碎句号 must flag the narrative block (line 1), not the dialogue cluster (lines 7-12).
const stutter = report.findings.find((f) => f.type === 'period-stutter');
if (stutter.line !== 1) {
  throw new Error(`period-stutter should start at the narrative block (line 1), got line ${stutter.line}`);
}
NODE
done

# --- MEDIUM-1：碎句号混合行（叙述 + 引号内物件）不能被一个引号整行豁免（#188 review） ---
FIXTURE3="$TMP_DIR/fixture-mixed-quote.md"
printf '%s\n' '他站起。他看见“门”。风进来。他回头。灯灭了。心一沉。' > "$FIXTURE3"
for SCRIPT in "${SCRIPTS[@]}"; do
set +e
run_detector "$SCRIPT" --json "$FIXTURE3" > "$OUT"
status=$?
run_detector "$SCRIPT" --fail-on=all "$FIXTURE3" >/dev/null 2>&1
status_all=$?
set -e
if [ "$status" -ne 0 ]; then
  echo "FAIL: mixed-quote period-stutter is advisory-only and should default exit 0, got $status ($SCRIPT)" >&2
  cat "$OUT" >&2 || true
  exit 1
fi
if [ "$status_all" -ne 1 ]; then
  echo "FAIL: mixed-quote period-stutter --fail-on=all should exit 1, got $status_all ($SCRIPT)" >&2
  exit 1
fi
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const st = r.findings.filter((f) => f.type === 'period-stutter');
if (st.length !== 1) throw new Error('混合引号叙述应命中碎句号: ' + JSON.stringify(r.findings.map((f) => f.type)));
if (st[0].severity !== 'advisory') throw new Error('period-stutter 应为 advisory');
NODE
done

# 纯对话成片短句仍豁免（体裁手法）。
FIXTURE4="$TMP_DIR/fixture-pure-dialogue.md"
printf '%s\n' '“走。”' '“快。”' '“跑。”' '“停。”' '“看。”' '“听。”' > "$FIXTURE4"
for SCRIPT in "${SCRIPTS[@]}"; do
set +e
pure_out="$(run_detector "$SCRIPT" "$FIXTURE4" 2>&1)"
pure_status=$?
set -e
if [ "$pure_status" -ne 0 ]; then
  echo "FAIL: 纯对话成片短句被误判碎句号 (exit $pure_status, $SCRIPT):" >&2
  echo "$pure_out" >&2
  exit 1
fi
done

# --- markdown 结构行不算正文叙述，长段落/破折号都跳过 ---
FIXTURE5="$TMP_DIR/fixture-heading.md"
node -e 'process.stdout.write("## " + "长".repeat(230) + "\n")' > "$FIXTURE5"
for SCRIPT in "${SCRIPTS[@]}"; do
set +e
head_out="$(run_detector "$SCRIPT" "$FIXTURE5" 2>&1)"
head_status=$?
set -e
if [ "$head_status" -ne 0 ]; then
  echo "FAIL: markdown 标题被误判 long-paragraph (exit $head_status, $SCRIPT):" >&2
  echo "$head_out" >&2
  exit 1
fi
done

FIXTURE5_DASH="$TMP_DIR/fixture-structural-dash.md"
printf '%s\n' '> 她停住——没说话。' '- 他回头--灯灭了。' > "$FIXTURE5_DASH"
for SCRIPT in "${SCRIPTS[@]}"; do
set +e
run_detector "$SCRIPT" --json "$FIXTURE5_DASH" > "$OUT"
dash_struct_status=$?
set -e
if [ "$dash_struct_status" -ne 0 ]; then
  echo "FAIL: markdown 结构行里的破折号不应触发 blocking，实际退出 $dash_struct_status ($SCRIPT)" >&2
  cat "$OUT" >&2 || true
  exit 1
fi
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const dash = r.findings.filter((f) => f.type === 'em-dash');
if (dash.length !== 0) throw new Error('结构行破折号不应检出: ' + JSON.stringify(r.findings));
NODE
done

# --- severity 字段 + --fail-on 语义：仅 advisory（long-paragraph）时默认退出 0，严格模式退出 1 ---
FIXTURE6="$TMP_DIR/fixture-advisory.md"
node -e 'process.stdout.write("他沿着长廊一直往里走，" + "走过一道又一道紧闭的木门，".repeat(16) + "终于在尽头停下。\n")' > "$FIXTURE6"
for SCRIPT in "${SCRIPTS[@]}"; do
set +e
run_detector "$SCRIPT" --json "$FIXTURE6" > "$OUT"
adv_default=$?
run_detector "$SCRIPT" --fail-on=all "$FIXTURE6" >/dev/null 2>&1
adv_all=$?
run_detector "$SCRIPT" --fail-on=blocking "$FIXTURE6" >/dev/null 2>&1
adv_blk=$?
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
if (!r.findings.length) throw new Error('expected long-paragraph finding');
if (!r.findings.every((f) => f.severity === 'advisory')) {
  throw new Error('long-paragraph-only fixture 应全为 advisory: ' + JSON.stringify(r.findings.map((f) => f.severity)));
}
NODE
[ "$adv_default" -eq 0 ] || { echo "FAIL: advisory-only 默认 --fail-on=blocking 应退出 0，实际 $adv_default" >&2; exit 1; }
[ "$adv_all" -eq 1 ] || { echo "FAIL: advisory-only --fail-on=all 应退出 1，实际 $adv_all" >&2; exit 1; }
[ "$adv_blk" -eq 0 ] || { echo "FAIL: advisory-only --fail-on=blocking 应退出 0，实际 $adv_blk" >&2; exit 1; }
done

# 空行必须切断碎句号 run；半角句号必须参与短句切分。
FIXTURE6_BLANK="$TMP_DIR/fixture-stutter-blank.md"
printf '%s\n\n%s\n\n%s\n' '他停下。她回头。灯灭了。' '风进来。门合上。' '心一沉。' > "$FIXTURE6_BLANK"
FIXTURE6_DOT="$TMP_DIR/fixture-stutter-dot.md"
printf '%s\n' '他停下. 她回头. 灯灭了. 风进来. 门合上. 心一沉.' > "$FIXTURE6_DOT"
for SCRIPT in "${SCRIPTS[@]}"; do
set +e
blank_out="$(run_detector "$SCRIPT" "$FIXTURE6_BLANK" 2>&1)"
blank_status=$?
run_detector "$SCRIPT" --json "$FIXTURE6_DOT" > "$OUT"
dot_status=$?
run_detector "$SCRIPT" --fail-on=all "$FIXTURE6_DOT" >/dev/null 2>&1
dot_all=$?
set -e
if [ "$blank_status" -ne 0 ]; then
  echo "FAIL: 空行分隔的短句不应累计成碎句号 (exit $blank_status, $SCRIPT):" >&2
  echo "$blank_out" >&2
  exit 1
fi
if [ "$dot_status" -ne 0 ] || [ "$dot_all" -ne 1 ]; then
  echo "FAIL: 半角句号短句应 advisory 默认 0 / all 1，实际 default=$dot_status all=$dot_all ($SCRIPT)" >&2
  cat "$OUT" >&2 || true
  exit 1
fi
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
if (!r.findings.some((f) => f.type === 'period-stutter')) {
  throw new Error('半角句号短句未触发 period-stutter');
}
NODE
done

# blocking（em-dash）：severity=blocking，--fail-on=blocking 退出 1。
FIXTURE7="$TMP_DIR/fixture-blocking.md"
printf '%s\n' '她停住——没说话。' > "$FIXTURE7"
for SCRIPT in "${SCRIPTS[@]}"; do
set +e
run_detector "$SCRIPT" --json "$FIXTURE7" > "$OUT"
run_detector "$SCRIPT" --fail-on=blocking "$FIXTURE7" >/dev/null 2>&1
blk_blk=$?
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const dash = r.findings.find((f) => f.type === 'em-dash');
if (!dash || dash.severity !== 'blocking') throw new Error('em-dash 应为 blocking: ' + JSON.stringify(dash));
NODE
[ "$blk_blk" -eq 1 ] || { echo "FAIL: em-dash --fail-on=blocking 应退出 1，实际 $blk_blk" >&2; exit 1; }
done

FIXTURE8="$TMP_DIR/fixture-ascii-dash-markup.md"
printf '%s\n' '<!-- hidden note -->' 'node check-ai-patterns.js --json file.md' > "$FIXTURE8"
for SCRIPT in "${SCRIPTS[@]}"; do
set +e
ascii_dash_out="$(run_detector "$SCRIPT" "$FIXTURE8" 2>&1)"
ascii_dash_status=$?
set -e
if [ "$ascii_dash_status" -ne 0 ]; then
  echo "FAIL: HTML 注释/CLI 参数里的 -- 不应判为正文破折号 (exit $ascii_dash_status, $SCRIPT):" >&2
  echo "$ascii_dash_out" >&2
  exit 1
fi
done

echo "Prose pattern (碎句号/长段落/破折号) regression tests passed."
