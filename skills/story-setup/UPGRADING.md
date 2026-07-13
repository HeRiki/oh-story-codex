# 升级指南

## 升级策略

| 策略 | 适用场景 | 风险 |
|------|----------|------|
| 覆盖部署 | 全新项目或无需保留自定义 | 低 |
| 合并部署 | 有自定义内容需保留 | 中 |
| 手动更新 | 只改特定文件 | 低 |

推荐：运行 `/story-setup` 重新部署，自动走合并策略。

## 文件分类

### 可安全覆盖

这些文件由 story-setup 管理，不含用户自定义内容：
- `.codex/story-agents/` — 所有 story agent 参考提示词
- `.codex/agents/` — Codex custom agent TOML
- `.codex/hooks/story_codex_hook.py` — Codex 项目级 hook adapter
- `.codex/story-rules/` — 所有写作规则参考
- `.codex/story-agent-references/` — story agent 参考资料副本
- `.codex/skills/story-setup/references/agent-references/` — Codex custom agents 的主参考资料副本

### 需合并（不覆盖）

这些文件可能含用户自定义内容：
- `AGENTS.md` — 按 section 合并，用户独有 section 保留
- `.codex/hooks.json` — hooks 按 command 去重 append，用户已有其他配置保留

### 不碰

这些文件完全由用户管理：
- `{书名}/追踪/上下文.md` — 用户写作上下文
- `{书名}/追踪/伏笔.md` — 用户伏笔追踪
- `.active-book` — 用户活跃书目
- 短篇项目的 `追踪/` — setup/hooks 不应为短篇自动创建

> Codex 插件级 lifecycle hooks 由本仓库 `.codex-plugin/plugin.json` 和 `hooks/hooks.json` 加载；`story-setup` 另可部署项目级 `.codex/hooks.json` 与 `.codex/hooks/story_codex_hook.py`，用于把写作项目自己的 hook 配置随项目落盘。

## 版本检测

`.story-deployed` 文件记录部署版本：
- 无此文件 → 未部署，需全新安装
- `agents_version: 1` → 旧版，需重新部署以获取新版参考提示词
- `agents_version: 2` → 旧版，需重新部署以获取 story-explorer 参考提示词
- `agents_version: 3` → 旧版，需重新部署以获取 story-explorer 参考提示词
- `agents_version: 4` → 旧版，需重新部署以获取 v5 narrative-writer 参考提示词
- `agents_version: 5` → 旧版，需重新部署以统一短篇正文格式
- `agents_version: 6` → 旧版，需重新部署以获取日更续写规则修复
- `agents_version: 7` → 旧版，需重新部署以获取 agent 参考文件路径修复
- `agents_version: 8` → 旧版，需重新部署以获取 v9 reference bundle、规则格式修复和 reviewer fallback 更新
- `agents_version: 9` → 旧版，需重新部署以获取新版写作 Agent、文风档案沿用和流程衔接更新
- `agents_version: 10` → 旧版，需重新部署以获取 agent 模板枚举漂移修复和 reference 去重/命名更新
- `agents_version: 11` → 旧版，需重新部署以获取 Windows 字数统计解释器探测修复
- `agents_version: 12` → 旧版，需重新部署以获取拆文契约、基调枚举和标点格式修复
- `agents_version: 13` → 旧版，需重新部署以获取 prompt-cache 优化、破折号过滤和标点规范化修复
- `agents_version: 14` → 旧版，需重新部署以获取拆文到写作模块链、推理型一致性检查、自然分段和主语节奏规则
- `agents_version: 15` → 旧版，需重新部署以获取 AI 句式检测、对话声线/文风自检、新名词锚点、封面裁剪兜底、Codex custom agents 和项目级 hooks
- `agents_version: 16` → 旧版，需重新部署以获取题材正文提示卡召回、chapter_formula 逐章写法公式和新版部署模板
- `agents_version: 17` → 当前版本

## 版本变更

### v2

- 4 个创作型参考提示词 + 1 个研究型参考提示词（story-architect, character-designer, narrative-writer, consistency-checker, story-researcher）
- 参考提示词引用 skill references 写作理论
- 4 条写作规则参考

### v3

- 新增 story-explorer 只读查询参考提示词（角色/伏笔/设定/进度查询，日更上下文快速加载）
- 6 个参考提示词总计（story-architect, character-designer, narrative-writer, consistency-checker, story-researcher, story-explorer）
- story-explorer 被 story-long-write、story-review、story 路由作为参考使用

### v4

- 新增 chapter-extractor 章节提取参考提示词
- 7 个参考提示词总计（story-architect, character-designer, narrative-writer, consistency-checker, story-researcher, story-explorer, chapter-extractor）

### v5

- 更新 narrative-writer 场景写法：使用“三维度织入”并按镜头断段控制段落密度
- 字数统计改为 Python 字符统计优先，`wc -m` 仅作 macOS/Linux 备选，提升 Windows + Codex 兼容性
- 已部署项目重新运行 `/story-setup` 后获取新版 story agent 参考提示词

### v6

- 统一 narrative-writer 参考提示词与主会话的短篇正文格式：固定写入 `正文.md`、小节标记统一、段落无空行、对话半角双引号。
- 短篇写作不再由 narrative-writer 创建长篇 `追踪/上下文.md`。

### v7

- 修复长篇 `/story-long-write 日更` 批量续写中的 continuation 规则：同一批次内“继续/续写/日更”保持在 daily workflow，不直接跳到正文续写。
- 修复伏笔缺口提示语义：正常开放伏笔（`未埋`/`已埋`）不是缺口；只有 `已过期` 或异常状态需要提示。
- Codex 插件级 lifecycle hook 由本仓库插件加载，不由 `/story-setup` 写入用户项目目录；升级本插件后重新打开会话即可使用新版 hook 行为。已部署项目重新运行 `/story-setup` 用于刷新 `.codex/story-agents/` 和 `.codex/story-rules/`。

### v8

- 修复 story-review 及部署后的 reviewer agent 在项目根目录下读取参考文件时，只找裸文件名导致找不到 skill references 的问题。
- agent 模板新增参考文件路径规则：优先从本仓库 `skills/` 或 Codex 全局 skills 目录解析 `story-setup/references/agent-references/*.md` 规范路径，避免依赖当前工作目录且不跨 skill 引用 references。
- 已部署项目需重新运行 `/story-setup`，以覆盖 `.codex/story-agents/` 并获得新版参考文件路径规则。

### v9

- `setup_skill_version` 升级到 `1.1.0`，`.story-deployed` 的 `agents_version` 升级到 `9`。
- 部署契约补充机械可检查清单：`AGENTS.md`、story rules、story agents、Agent References、上下文模板和 `.story-deployed` 字段都必须明确 source、target、owner、merge mode、validation。
- Agent Reference bundle 补齐并 canonicalize：
  - `genre-readers.md`：从 story-long-write 参考资料复制为 story-setup canonical 副本。
  - `genre-writing-formulas.md`：从 story-long-write 参考资料复制为 story-setup canonical 副本。
  - `emotional-methods.md`：从 story-long-write 参考资料复制为 story-setup canonical 副本。
  - `style-combat-face.md`：从 story-long-write 参考资料复制为 story-setup canonical 副本。
  - `output-templates.md`：不复制；`chapter-extractor` 已内置输出格式，旧的裸引用改写为“遵循本文件输出格式”。
- `story-format.md` 删除“章节之间用 `---` 分隔”的旧规则，改为禁止正文片段使用水平分隔线，与 narrative-writer 保持一致。
- `story-review` 增加 stale deployment 检查与内置 rubric fallback；`.story-deployed` 版本小于 9 时自动降级 solo 并建议重新运行 `/story-setup`。
- `browser-cdp` 启动脚本新增 `--detect-only`、`--yes`、`--reset`、`--profile`，避免在未确认时结束用户常规 Chrome。

### v10

- `setup_skill_version` 升级到 `1.1.1`，`.story-deployed` 的 `agents_version` 升级到 `10`。
- 刷新 7 个 story agent 参考提示词，尤其是 `narrative-writer`：日更续写时更稳定地沿用对标文风与项目文风档案。
- 补充 `story-setup` 与 `story-review` 的流程衔接说明，方便部署后直接进入写作、导入、扫榜或审查流程。
- 同步 v0.6.12 上游 reference bundle：选题决策、女频长篇 playbook、短篇 output contract、跨书召回、七类反转和术语白话化。

### v11

- `setup_skill_version` 升级到 `1.1.2`，`.story-deployed` 的 `agents_version` 升级到 `11`。
- 刷新 story agent 参考提示词，修复 `story-architect` 反转类型枚举与 `character-designer` 关系命名枚举漂移。
- 同步 reference 去重和命名更新：旧的 style-commercial-theory 文件改为 `commercial-core-methods.md`，商业核心方法、剧情框架、写作技法等重复块改为同 skill 内指针。
- 写作 reference 补充可落地网文例子，删去空泛比喻和难执行的抽象公式。

### v12

- `setup_skill_version` 升级到 `1.1.3`，`.story-deployed` 的 `agents_version` 升级到 `12`。
- 刷新 `narrative-writer` 参考提示词，字数统计改为 `python3→python→py` 实跑探测，避免 Windows 上 `python3` 触发 Microsoft Store 占位程序并以 exit 49 静默失败。
- 已部署项目重新运行 `/story-setup` 后可刷新 `.codex/story-agents/narrative-writer.md` 与相关规则说明。

### v13

- `setup_skill_version` 升级到 `1.1.4`，`.story-deployed` 的 `agents_version` 升级到 `13`。
- 刷新 `chapter-extractor`、`story-explorer`、`story-researcher`、`consistency-checker` 与 `narrative-writer` 参考提示词，补齐长篇拆文基调/主题枚举、文风锚点保真、盐言引号保留和标点格式规则。
- 刷新 agent reference bundle 中的 banned-words、anti-ai-writing、dialogue/format/writing 参考，包含「不是A，（而）是B」变体和 `「」` 引号兼容。
- 已部署项目重新运行 `/story-setup` 后可刷新 `.codex/story-agents/`、`.codex/story-agent-references/` 与 `.story-deployed`。

### v14

- `setup_skill_version` 升级到 `1.1.5`，`.story-deployed` 的 `agents_version` 升级到 `14`。
- 刷新 `narrative-writer`、`chapter-extractor`、`consistency-checker` 等参考提示词，继承上游 v0.6.16 的 prompt-cache 优化、写作破折号过滤、规范化器误伤修复和拆解管道合法性语境补强。
- 刷新 agent reference bundle 中的 anti-ai-writing、banned-words、format-and-structure 等参考，保持 story-deslop / story-review / write skill 的标点规范一致。
- 已部署项目重新运行 `/story-setup` 后可刷新 `.codex/story-agents/`、`.codex/story-agent-references/` 与 `.story-deployed`。

### v15

- `setup_skill_version` 升级到 `1.1.6`，`.story-deployed` 的 `agents_version` 升级到 `15`。
- 同步上游 main（v0.6.16 后）：`story-long-analyze` Stage 2/3 增加「关键信息与扩写技法」「剧情/节奏.md」「剧情/情绪模块.md」等可复用写作模块，`story-import` 与 `story-long-write` 对应消费这些对标资产。
- 刷新 `chapter-extractor`、`story-explorer`、`consistency-checker`、`narrative-writer` 等参考提示词：补推理型一致性检查、自然分段、主语节奏、解释腔/上帝感/安排感识别与情绪烈度检查。
- Codex 插件级 PreToolUse hook 新增正文前置检查：首次创建长篇 `正文/第N章_*.md` 时要求已有对应 `大纲/细纲_第N章.md`，首次创建短篇 `正文.md` 时要求已有 `小节大纲.md`；续写/改稿/导入迁移场景放行。
- 已部署项目重新运行 `/story-setup` 后可刷新 `.codex/story-agents/`、`.codex/story-agent-references/` 与 `.story-deployed`；插件级 hook 随仓库更新加载，不写入用户项目目录。

### v16

- `setup_skill_version` 升级到 `1.2.5`，`.story-deployed` 的 `agents_version` 保持 `16`。
- 同步上游 v0.6.19-v0.6.21：短篇参考栈重构、长篇章节定位与张弛、模型退化检测、AI 句式检测增强、Codex custom agents 和项目级 hooks。
- 新增 `.codex/agents/*.toml`：由 `scripts/generate-codex-agents.py` 从角色提示词模板确定性生成。
- 新增 `.codex/hooks.json` 与 `.codex/hooks/story_codex_hook.py`：提供正文前置检查、compact 上下文提示、Stop 阶段正文兜底复扫和跨批连续性提示。
- `skills/story/VERSION` 更新到 `0.6.21`；检查更新只提示，不自动更新。

已部署项目需重新运行 `/story-setup`，以覆盖 `.codex/story-agents/`、`.codex/agents/`、`.codex/story-rules/` 并部署 `.codex/story-agent-references/`、`.codex/skills/story-setup/references/agent-references/` 和项目级 hooks。

### v17 (当前)

- `setup_skill_version` 升级到 `1.2.6`，`.story-deployed` 的 `agents_version` 升级到 `17`。
- 同步上游 v0.6.22：长篇新增题材正文提示卡召回，短篇新增投稿层，去 AI 味检测补充任务卡点、动作链和比喻密度提示。
- 刷新 `narrative-writer` 与 `chapter-extractor` 部署模板：写作前按 `设定/题材定位.md` 召回题材卡，正文禁止泄漏卡名/题材标签/置信度/合规自评；拆文阶段新增 `chapter_formula` 逐章写法公式。
- `skills/story/VERSION` 更新到 `0.6.22`；检查更新只提示，不自动覆盖本仓 Codex 移植版。

已部署项目需重新运行 `/story-setup`，以覆盖 `.codex/story-agents/`、`.codex/agents/`、`.codex/story-rules/`、`.codex/story-agent-references/`、`.codex/skills/story-setup/references/agent-references/` 和项目级 hooks；部署后新开 Codex 会话让 custom agents 重新注册。
