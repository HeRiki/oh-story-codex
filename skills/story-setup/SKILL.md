---
name: story-setup
description: |
  Codex 网文写作项目初始化。将 AGENTS.md、story agents/rules 参考库、agent reference bundle 和上下文模板部署到用户写作项目目录。
  触发方式：/story-setup、「准备写书」「帮我搭一下环境」「配置写作项目」「初始化写作项目」
---

# story-setup：Codex 写作项目初始化

你是写作基础设施部署器。把网文写作项目需要的项目规则、角色提示词参考库、agent 参考资料副本和上下文模板部署到用户项目目录。

**执行铁律：不覆盖用户已有配置，合并而非替换。**

## Phase 1：检测项目状态

1. 检查当前目录是否已部署过（存在 `.story-deployed`）。
   - 如果已存在，直接向用户确认是否重新部署。
2. 检查是否有书名目录（包含 `追踪/` 子目录的目录，或用户自定义结构）。
   - 有：识别为长篇项目，展示当前项目信息。
   - 无：识别为新项目或短篇项目。
3. 检查项目根目录是否存在 `AGENTS.md`。
   - 存在：后续按 section 合并。
   - 不存在：后续创建新文件。
4. 检查 `.active-book` 文件是否存在。
   - 存在：读取当前活跃书目。
   - 不存在：跳过。

## Phase 2：部署基础设施

直接向用户确认部署位置后，依次执行。

### 2.0 部署清单（机械可检查）

| Source path | Target path | Owner class | Merge mode | Validation check |
|---|---|---|---|---|
| `references/templates/AGENTS.md.tmpl` | `AGENTS.md` | user+managed | section merge | 包含 Skill 路由表、文件结构、上下文恢复规则 |
| `references/templates/rules/*.md` | `.codex/story-rules/*.md` | story-setup managed | replace | 规则文件完整，且包含 `paths` frontmatter |
| `references/templates/agents/*.md` | `.codex/story-agents/*.md` | story-setup managed | replace | 7 个角色提示词完整，frontmatter 只保留 Codex 可读字段 |
| `references/agent-references/*.md` | `.codex/story-agent-references/*.md` | story-setup managed | replace | agent 模板引用的参考文件均有同名副本 |
| `references/templates/上下文.md.tmpl` | `{书名}/追踪/上下文.md` | user state | create only if absent | 不覆盖用户已有写作上下文 |
| generated sentinel | `.story-deployed` | story-setup managed | replace | 包含 `runtime: codex`、`agents_version: 16`、`setup_skill_version: 1.1.7` |

### 2.1 部署 AGENTS.md

- 读取 `references/templates/AGENTS.md.tmpl`。
- 替换占位符（见「模板占位符」）。
- 写入项目根目录 `AGENTS.md`；如已存在，按「AGENTS.md 合并策略」处理。

### 2.2 部署 story rules

- 读取 `references/templates/rules/` 下所有 `.md` 文件。
- 复制到用户项目的 `.codex/story-rules/` 目录。
- 这些文件是 Codex 可读取的写作规则参考，不是自动 hook。

### 2.3 部署 story agents 参考提示词

- 读取 `references/templates/agents/` 下所有 `.md` 文件。
- 复制到用户项目的 `.codex/story-agents/` 目录。
- Codex 不使用旧运行时的自定义子代理注册机制；需要多视角审查时，将这些文件作为 `spawn_agent` 或本线程审查的角色提示词参考。
- agent 模板中的参考资料路径统一指向 `story-setup/references/agent-references/*.md`，这是本 skill 自带的参考资料副本；不要跨 skill 读取其他 skill 的 references，也不要只写裸文件名。

### 2.4 部署 agent reference bundle

- 读取 `references/agent-references/` 下所有 `.md` 文件。
- 复制到用户项目的 `.codex/story-agent-references/` 目录，作为项目本地可读副本。
- 校验：凡 `.codex/story-agents/*.md` 或 reference 中出现 `story-setup/references/agent-references/<file>.md`，源包 `references/agent-references/<file>.md` 必须存在；项目本地 `.codex/story-agent-references/<file>.md` 也应存在同名副本。
- `output-templates.md` 不复制；`chapter-extractor` 已内置输出格式，遵循本文件「输出格式」章节即可。

### 2.5 部署上下文模板

- 读取 `references/templates/上下文.md.tmpl`。
- 如有书名目录且 `{书名}/追踪/` 已存在，复制到 `{书名}/追踪/上下文.md`。
- 如果目标文件已存在，不覆盖，只提示已有。
- 短篇项目不得因此创建 `追踪/` 目录。

### 2.6 创建部署标记

创建 `.story-deployed`，写入：

```text
deployed_at: <date -u +"%Y-%m-%dT%H:%M:%SZ">
runtime: codex
agents_version: 16
setup_skill_version: 1.1.7
resolver_strategy: codex-skill-reference
references_dir: .codex/story-agent-references
```

如果 `.story-deployed` 已存在但无 `agents_version` 或版本小于 16，提示用户重新运行 `/story-setup` 以更新 story agents/rules/reference bundle（具体变更见 `UPGRADING.md`）。

## Phase 3：验证安装

1. 检查 `AGENTS.md` 是否存在，且包含 Skill 路由表、文件结构、上下文恢复规则。
2. 检查 `.codex/story-rules/` 是否存在并包含规则文件。
3. 检查 `.codex/story-agents/` 是否存在并包含 7 个角色提示词。
4. 检查 `.codex/story-agent-references/` 是否存在，且包含所有 agent 模板引用的参考文件。
5. 检查 `.story-deployed` 是否存在且 `runtime: codex`、`agents_version: 16`、`setup_skill_version: 1.1.7`。
6. 输出安装报告，列出已部署文件和已保留的用户原有配置。

## 模板占位符

| 占位符 | 替换规则 | 示例 |
|---|---|---|
| `{项目名}` | 用户项目名称或目录名 | 《剑来》、《暗卫》 |
| `{书名}` | 书名目录名 | 与 `{项目名}` 相同，或用户自定义 |
| `{目标平台}` | 目标发布平台 | 起点、番茄、晋江、知乎盐言 |
| `{作者名}` | 用户笔名或昵称 | 未指定时用「作者」 |

替换时去掉花括号。如果用户未指定项目名，用当前目录名。未指定占位符保留原样。

## AGENTS.md 合并策略

用户已有 `AGENTS.md` 时，按二级标题合并：

1. 读取用户现有 `AGENTS.md`，按 `##` 标题切分为 section map。
2. 读取模板 `AGENTS.md.tmpl`，同样切分。
3. 模板中的标准 section（Skill 路由表、文件结构、协作规则、上下文恢复）覆盖用户同名 section。
4. 用户独有 section 保留不动。
5. 未知冲突直接向用户确认保留哪个版本。

## 重新部署

- `.story-deployed` 不存在：全新安装，Phase 2 全部执行。
- `.story-deployed` 存在且 `runtime: codex`、`agents_version: 16`：提示已部署，确认后重跑。
- `.story-deployed` 存在且 `runtime: codex`、`agents_version` 小于 16：提示需要重新部署以更新 story agents/rules/reference bundle，包含 agent 参考资料路径修复、短篇正文格式统一、日更续写 continuation 规则、伏笔降噪语义、v9 reference bundle、v10 写作 agent 文风沿用修复、v11 agent 枚举漂移修复、v12 Windows 字数统计解释器探测修复、v13 拆文契约/基调枚举/标点格式修复、v14 prompt-cache 优化/写作破折号过滤/标点规范化修复、v15 拆文到写作模块链、推理型一致性检查、自然分段/主语节奏规则更新，以及 v16 AI 句式检测、对话声线/文风自检、新名词锚点、封面裁剪兜底和版本提醒说明。
- `.story-deployed` 存在但 runtime 不是 `codex`：按迁移处理，部署 Codex 目录，不删除原有旧运行时目录。

## Codex lifecycle hook

Codex lifecycle hook 由本仓库插件机制加载，不由 `/story-setup` 写入用户项目目录。升级插件版本后，重新打开会话即可获得新版 hook 行为。

## 参考资料

| 文件 | 用途 |
|---|---|
| `references/templates/AGENTS.md.tmpl` | 项目根 `AGENTS.md` 模板 |
| `references/templates/rules/` | 写作规则参考 |
| `references/templates/agents/` | 7 个角色提示词参考，含 v16 AI 句式检测、对话声线/文风自检、新名词锚点与具体字数表达校验，v15 拆文到写作模块链、推理型一致性检查、自然分段/主语节奏规则，v14 prompt-cache 优化、破折号过滤与标点规范化修复，v13 拆文契约、基调/主题枚举、文风锚点，以及 v12 Windows 字数统计解释器探测修复 |
| `references/agent-references/` | agent 模板自带的参考资料副本，避免跨 skill references |
| `references/templates/上下文.md.tmpl` | 写作上下文模板 |
| `UPGRADING.md` | 已部署项目重新运行 `/story-setup` 时的升级策略和版本说明 |

## 流程衔接

**流水线：** 部署
**位置：** 初始化（最前置）

| 时机 | 跳转到 | 命令 |
|---|---|---|
| 部署完成，开始长篇写作 | story-long-write | `/story-long-write` |
| 部署完成，开始短篇写作 | story-short-write | `/story-short-write` |
| 导入已有小说做拆解 | story-import | `/story-import` |
| 需要浏览器登录态（扫榜/拆文取原文） | browser-cdp | `/browser-cdp` |
