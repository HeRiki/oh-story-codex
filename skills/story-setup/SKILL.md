---
name: story-setup
description: |
  Codex 网文写作项目初始化。将 AGENTS.md、story rules、角色提示词参考、Codex custom agents、Codex hooks 和 agent reference bundle 部署到用户写作项目目录。
  触发方式：/story-setup、$story-setup、「准备写书」「帮我搭一下环境」「配置写作项目」「初始化写作项目」
---

# story-setup：Codex 写作项目初始化

你是写作基础设施部署器。把网文写作项目需要的项目规则、角色提示词、Codex custom agents、Codex hooks、agent 参考资料副本和上下文模板部署到用户项目目录。

**执行铁律：不覆盖用户已有配置，合并而非替换。**

## Phase 1：检测项目状态

1. 检查当前目录是否已部署过（存在 `.story-deployed`）。
   - 如果已存在，直接向用户确认是否重新部署。
2. 检查是否有书名目录（包含 `追踪/` 子目录的目录，或用户自定义结构）。
   - 有：识别为长篇项目，展示当前项目信息。
   - 无：识别为新项目或短篇项目。
3. 检查项目根目录是否存在 `AGENTS.md`。
   - 存在：后续按 section/marker 合并。
   - 不存在：后续创建新文件。
4. 检查 `.active-book` 文件是否存在。
   - 存在：读取当前活跃书目。
   - 不存在：跳过。
5. 检查 `.codex/`、`.codex/agents/`、`.codex/hooks.json` 是否存在。
   - 存在：后续合并 hooks，并替换 story-setup 管理的 custom agent 文件。
   - 不存在：创建 `.codex/` 目录树。

## Phase 2：部署基础设施

向用户确认部署位置后，依次执行。

### 2.0 部署清单（机械可检查）

| Source path | Target path | Owner class | Merge mode | Validation check |
|---|---|---|---|---|
| `references/codex/AGENTS.md.tmpl` | `AGENTS.md` | user+managed | section/marker merge | 包含 Codex skill 路由、文件结构、上下文恢复规则 |
| `references/templates/rules/*.md` | `.codex/story-rules/*.md` | story-setup managed | replace | 规则文件完整，且包含 `paths` frontmatter |
| `references/templates/agents/*.md` | `.codex/story-agents/*.md` | story-setup managed | replace | 7 个角色提示词完整，frontmatter 只保留 Codex 可读字段 |
| `references/codex/agents/*.toml` | `.codex/agents/*.toml` | story-setup managed | replace | 7 个 TOML custom agents 可解析，包含 `name`、`description`、`developer_instructions` |
| `references/codex/hooks/hooks.json` | `.codex/hooks.json` | user+managed | merge by hook command | JSON 有效，hook command 去重合并 |
| `references/codex/hooks/{story_codex_hook.py,run-story-hook.sh,run-story-hook.cmd}` | `.codex/hooks/` 同名文件 | story-setup managed | replace | Python/POSIX/Windows launcher 文件齐全，UTF-8 stdin/stdout |
| `references/agent-references/*.md` | `.codex/story-agent-references/*.md` | story-setup managed | replace | legacy 参考提示词可读 |
| `references/agent-references/*.md` | `.codex/skills/story-setup/references/agent-references/*.md` | story-setup managed | replace | Codex custom agents 的项目内主参考路径完整 |
| generated sentinel | `.story-deployed` | story-setup managed | replace | 包含 `runtime: codex`、`agents_version: 25`、`setup_skill_version: 1.2.7` |

### 2.1 部署 AGENTS.md

- 读取 `references/codex/AGENTS.md.tmpl`。
- 替换占位符（见「模板占位符」）。
- 写入项目根目录 `AGENTS.md`；如已存在，按「AGENTS.md 合并策略」处理。

### 2.2 部署 story rules

- 读取 `references/templates/rules/` 下所有 `.md` 文件。
- 复制到用户项目的 `.codex/story-rules/` 目录。
- 这些文件是 Codex 可读取的写作规则参考，不是自动 hook。

### 2.3 部署 story agents 参考提示词

- 读取 `references/templates/agents/` 下所有 `.md` 文件。
- 复制到用户项目的 `.codex/story-agents/` 目录。
- 这是角色提示词参考层，供本线程或 fallback 模式读取。
- agent 模板中的参考资料路径统一指向 `story-setup/references/agent-references/*.md`，这是本 skill 自带的参考资料副本；不要跨 skill 读取其他 skill 的 references，也不要只写裸文件名。

### 2.4 部署 Codex custom agents

- 读取 `references/codex/agents/` 下所有 `.toml` 文件。
- 复制到用户项目 `.codex/agents/` 目录。
- Agent 文件属于 story-setup 管理文件，可安全覆盖。
- 校验每个 TOML 都能解析，且包含 Codex 必需字段：`name`、`description`、`developer_instructions`。
- 只读职责 agent（`chapter-extractor`、`consistency-checker`、`story-explorer`）必须保留 `sandbox_mode = "read-only"`。
- **部署后必须 trust + 新开 Codex 会话**：项目 `.codex/` 配置层需要被 trust；部署后需要新会话/刷新后才可能稳定暴露给 spawn。若运行时返回 `unknown agent_type`，调用方必须降级 solo/direct 并报告 fallback。

### 2.5 部署 Codex hooks

- 读取 `references/codex/hooks/hooks.json`。
- 读取用户现有 `.codex/hooks.json`（如存在），保留未知字段。
- 调用 `scripts/merge-codex-hooks.py` 合并 hooks：只移除实际执行旧版 `story_codex_hook.py` 或新版 `run-story-hook.sh` / `run-story-hook.cmd` 的 story-setup 管理注册，再追加当前模板；仅在参数或说明文字中提到这些路径的用户自定义 hooks 与未知顶层字段保留。
- 复制 `references/codex/hooks/story_codex_hook.py`、`run-story-hook.sh`、`run-story-hook.cmd` 到 `.codex/hooks/`。
- 写入后提示用户：项目 `.codex/` 层需要被 Codex trust，非 managed command hooks 还需要在 `/hooks` 中 review/trust 后才会运行。

### 2.6 部署 agent reference bundle

- 将 `references/agent-references/` 下所有 `.md` 复制到 `.codex/story-agent-references/`，作为 legacy 参考提示词可读副本。
- 同步复制到 `.codex/skills/story-setup/references/agent-references/`，作为 Codex custom agents 的项目内主路径。
- 校验：凡 `.codex/story-agents/*.md`、`.codex/agents/*.toml` 或 reference 中出现 `story-setup/references/agent-references/<file>.md`，源包与目标包都必须存在 `<file>.md`。
- `output-templates.md` 不复制；`chapter-extractor` 已内置输出格式，遵循本文件「输出格式」章节即可。

### 2.7 追踪状态边界

- story-setup 不创建或改写任何书目下的 `追踪/` 文件。
- 长篇追踪以 `追踪/_tracking-state.json` 为唯一权威；`追踪/上下文.md`、伏笔、时间线和角色状态均由 `story-long-write/scripts/tracking_commit.py` 的 `init` / `commit` 确定性生成。
- 已有正文但缺少当前追踪状态时，按 story-import 的旧项目迁移流程归档旧追踪并重建；不要用模板或手写 Markdown 伪造当前状态。

### 2.8 创建部署标记

创建 `.story-deployed`，写入：

```text
deployed_at: <date -u +"%Y-%m-%dT%H:%M:%SZ">
runtime: codex
agents_version: 25
setup_skill_version: 1.2.7
resolver_strategy: codex-project-reference
references_dir: .codex/skills/story-setup/references/agent-references
```

如果 `.story-deployed` 已存在但无 `agents_version` 或版本小于 25，提示用户重新运行 `$story-setup` 以更新 story agents、Codex custom agents、hooks、rules 和 reference bundle（具体变更见 `UPGRADING.md`）。如果 `agents_version` 大于 25，停止部署并提示先更新本仓，避免降级覆盖用户项目。

## Phase 3：验证安装

1. 检查 `AGENTS.md` 是否存在，且包含 Codex skill 路由、文件结构、上下文恢复规则。
2. 检查 `.codex/story-rules/` 是否存在并包含规则文件。
3. 检查 `.codex/story-agents/` 是否存在并包含 7 个角色提示词。
4. 检查 `.codex/agents/` 是否存在并包含 7 个 TOML custom agents，且 TOML 可解析。
5. 检查 `.codex/hooks.json` 和 `.codex/hooks/story_codex_hook.py` 是否存在，JSON/Python 语法有效。
6. 检查 `.codex/story-agent-references/` 和 `.codex/skills/story-setup/references/agent-references/` 是否存在，且包含所有 agent 模板引用的参考文件。
7. 检查 `.story-deployed` 是否存在且 `runtime: codex`、`agents_version: 25`、`setup_skill_version: 1.2.7`。
8. 输出安装报告，列出已部署文件、已保留的用户原有配置、需要 trust 的 `.codex/` 配置，以及“新开 Codex 会话后 custom agents 才稳定可用”的提示。

## 模板占位符

| 占位符 | 替换规则 | 示例 |
|---|---|---|
| `{项目名}` | 用户项目名称或目录名 | 《剑来》、《暗卫》 |
| `{书名}` | 书名目录名 | 与 `{项目名}` 相同，或用户自定义 |
| `{目标平台}` | 目标发布平台 | 起点、番茄、晋江、知乎盐言 |
| `{作者名}` | 用户笔名或昵称 | 未指定时用「作者」 |

替换时去掉花括号。如果用户未指定项目名，用当前目录名。未指定占位符保留原样。

## AGENTS.md 合并策略

用户已有 `AGENTS.md` 时，按 marker/section 合并：

1. 优先识别 story-setup 管理块标记；已有标记时只替换标记内内容。
2. 无标记时，读取用户现有 `AGENTS.md`，按 `##` 标题切分为 section map。
3. 读取 `references/codex/AGENTS.md.tmpl`，同样切分。
4. 模板中的标准 section（Skill 路由表、文件结构、协作规则、上下文恢复）覆盖用户同名 section。
5. 用户独有 section 保留不动。
6. 未知冲突直接向用户确认保留哪个版本。

## 重新部署

- `.story-deployed` 不存在：全新安装，Phase 2 全部执行。
- `.story-deployed` 存在且 `runtime: codex`、`agents_version: 25`：提示已部署，确认后重跑。
- `.story-deployed` 存在且 `runtime: codex`、`agents_version` 小于 25：提示需要重新部署以更新 Codex custom agents、hooks、rules 和 reference bundle。
- `.story-deployed` 存在且 `runtime: codex`、`agents_version` 大于 25：停止部署，提示先更新本仓，避免用旧 story-setup 降级覆盖新项目。
- `.story-deployed` 存在但 runtime 不是 `codex`：按迁移处理，部署 Codex 目录，不删除用户原有目录。

## Codex lifecycle hook

本仓作为 Codex 插件安装时，还会通过 `.codex-plugin/plugin.json` 加载仓库根 `hooks/story-lifecycle-hook.cjs`。该插件 hook 用于全局写作项目上下文注入、正文前置检查和提交提醒；`/story-setup` 部署的 `.codex/hooks/story_codex_hook.py` 是项目级 hook，适用于希望把 hook 配置随写作项目一并落盘的场景。

## 参考资料

| 文件 | 用途 |
|---|---|
| `references/codex/AGENTS.md.tmpl` | Codex 项目根 `AGENTS.md` 模板 |
| `references/codex/agents/` | Codex custom agent TOML 模板 |
| `references/codex/hooks/hooks.json` | Codex hooks 注册模板 |
| `references/codex/hooks/story_codex_hook.py` | Codex hook adapter |
| `references/codex/hooks/run-story-hook.sh` | POSIX launcher |
| `references/codex/hooks/run-story-hook.cmd` | Windows launcher |
| `references/templates/rules/` | 写作规则参考 |
| `references/templates/agents/` | 7 个角色提示词参考 |
| `references/agent-references/` | agent 模板自带的参考资料副本，避免跨 skill references |
| `UPGRADING.md` | 已部署项目重新运行 `/story-setup` 时的升级策略和版本说明 |

## 流程衔接

**流水线：** 部署
**位置：** 初始化（最前置）

| 时机 | 跳转到 | 命令 |
|---|---|---|
| 部署完成，开始长篇写作 | story-long-write | `/story-long-write` 或 `$story-long-write` |
| 部署完成，开始短篇写作 | story-short-write | `/story-short-write` 或 `$story-short-write` |
| 导入已有小说做拆解 | story-import | `/story-import` 或 `$story-import` |
| 需要浏览器登录态（扫榜/拆文取原文） | browser-cdp | `/browser-cdp` 或 `$browser-cdp` |
