---
name: story-setup
description: |
  Codex 网文写作项目初始化。将 AGENTS.md、story agents/rules 参考库和上下文模板部署到用户写作项目目录。
  触发方式：/story-setup、「准备写书」「帮我搭一下环境」「配置写作项目」「初始化写作项目」
---

# story-setup：Codex 写作项目初始化

你是写作基础设施部署器。把网文写作项目需要的项目规则、角色提示词参考库和上下文模板部署到用户项目目录。

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

直接向用户确认部署位置后，依次执行：

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
- Codex 没有 Claude 的自定义 `subagent_type` 注册机制；需要多视角审查时，将这些文件作为 `spawn_agent` 或本线程审查的角色提示词参考。

### 2.4 部署上下文模板

- 读取 `references/templates/上下文.md.tmpl`。
- 如有书名目录，复制到 `{书名}/追踪/上下文.md`；文件已存在时不覆盖，只提示已有。

### 2.5 创建部署标记

创建 `.story-deployed`，写入：

```text
deployed_at: <date -u +"%Y-%m-%dT%H:%M:%SZ">
runtime: codex
agents_version: 3
setup_skill_version: 1.0.0
```

## Phase 3：验证安装

1. 检查 `AGENTS.md` 是否存在，且包含 Skill 路由表、文件结构、上下文恢复规则。
2. 检查 `.codex/story-rules/` 是否存在并包含规则文件。
3. 检查 `.codex/story-agents/` 是否存在并包含 6 个角色提示词。
4. 检查 `.story-deployed` 是否存在且 `runtime: codex`。
5. 输出安装报告，列出已部署文件和已保留的用户原有配置。

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
- `.story-deployed` 存在且 `runtime: codex`、`agents_version: 3`：提示已部署，确认后重跑。
- `.story-deployed` 存在但 runtime 不是 `codex`：按迁移处理，部署 Codex 目录，不删除原有 Claude 目录。

## 参考资料

| 文件 | 用途 |
|---|---|
| `references/templates/AGENTS.md.tmpl` | 项目根 `AGENTS.md` 模板 |
| `references/templates/rules/` | 写作规则参考 |
| `references/templates/agents/` | 6 个角色提示词参考 |
| `references/templates/上下文.md.tmpl` | 写作上下文模板 |
