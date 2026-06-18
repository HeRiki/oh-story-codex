**中文** | [English](README_EN.md)

# oh-story-codex

Codex 版中文网文写作技能包，由 `worldwonderer/oh-story-claudecode` 转换而来。它保留原包的扫榜、拆文、写作、审查、去 AI 味、导入和封面生成方法论，并把 skill metadata 转成 Codex 可识别格式。

> 这是非官方 Codex 移植版，不代表原作者发布或维护的官方版本。

## 核心思路

> **套路 = 确定性的情绪满足**

专业作者的方法论三步走：扫榜分析热门榜单，拆文沉淀结构和剧情素材，再把钩子、爽感、期待感等模块重新组合进自己的作品。这个包围绕爆款逆向、剧情模块化重组、上下文状态分层管理、人机协同四条线展开。

## 包含的 Skills

| Skill | 用途 |
|---|---|
| `story` | 工具箱路由入口，根据用户意图分发到具体写作流程，并支持多书切换 |
| `story-setup` | 初始化 Codex 写作项目结构和项目级 `AGENTS.md` |
| `story-long-scan` | 长篇平台扫榜和题材趋势分析 |
| `story-long-analyze` | 长篇爆款拆文、黄金三章和深度拆解 |
| `story-long-write` | 长篇开书、大纲、日更续写和章节修订 |
| `story-short-scan` | 短篇平台扫榜和风口题材分析 |
| `story-short-analyze` | 短篇结构、情绪曲线、反转和钩子拆解 |
| `story-short-write` | 短篇构思、分节写作和成稿精修 |
| `story-deslop` | 检测并降低网文中的 AI 写作痕迹 |
| `story-review` | 多视角故事质量审查 |
| `story-import` | 把已有小说反向解析为可续写项目结构 |
| `story-cover` | 网文封面提示词与图像生成流程 |
| `browser-cdp` | 通过 CDP 复用 Chrome 登录态做页面采集 |

## Demo

本仓库同步保留上游 v0.6.16 demo，用于展示拆文产物和导入后的可续写工程结构。部分 demo 按上游原样包含原文备份或示例正文，用于验证拆文、导入和续写链路。

主要文件：

```text
demo/拆文库-盘龙/
├── 概要.md
├── 拆文报告.md
├── 文风.md
├── 章节/
├── 角色/
├── 剧情/
├── 设定/
└── 原文/

demo/拆文库-曾将爱意私藏/
├── 拆文报告.md
├── 情节节点.md
├── 写作手法.md
└── 原文/

demo/让你管账号，你高燃混剪炸全网/
├── 正文/
├── 设定/
├── 大纲/
└── 追踪/
```

## Codex 使用方式

本仓库本身就是一个 Codex 插件目录，入口在 `.codex-plugin/plugin.json`，技能目录在 `skills/`。作为本地技能使用时，可以把需要的单个 skill 目录复制到 `$CODEX_HOME/skills/`；作为插件使用时，保留当前目录结构并通过 Codex 插件机制加载。

每个 `SKILL.md` 的 frontmatter 只保留 `name` 和 `description`，适配 Codex 的 skill 发现规则。`agents/openai.yaml` 提供 UI 元数据，不参与核心工作流。

`story-setup` 会把 7 个 story agent 参考提示词部署到写作项目的 `.codex/story-agents/`，并把 agent 参考资料副本部署到 `.codex/story-agent-references/`。它们不是 Claude 式自动注册子代理；Codex 默认读取这些文件作为角色说明，只有用户明确要求多代理/委派时才使用 `spawn_agent`。

| 参考提示词 | 用途 |
|---|---|
| `story-architect` | 故事架构、主线、世界观和长线伏笔 |
| `character-designer` | 人设、关系、动机和成长弧 |
| `narrative-writer` | 正文写作、续写和章节修订 |
| `consistency-checker` | 设定一致性、伏笔和时间线检查 |
| `story-researcher` | 资料检索与参考整理 |
| `story-explorer` | 只读查询项目资料和进度 |
| `chapter-extractor` | 深度拆文 Stage 2 的章节摘要、情节点和角色提取 |

插件级生命周期钩子定义在 `hooks/hooks.json`，由 `.codex-plugin/plugin.json` 的 `hooks` 字段加载。当前包含：

| Hook | 用途 |
|---|---|
| `PreToolUse` | 检测到即将执行 `git commit` 时，提醒先确认设定、大纲、追踪文件和文档是否同步 |
| `SessionStart` | 会话开始/恢复时读取已初始化网文项目的 `追踪/上下文.md`，并提示设定、大纲、正文、伏笔、时间线缺口 |
| `UserPromptSubmit` | 用户提交写作相关提示时，提醒优先读取项目上下文和追踪文件 |
| `Stop` | 默认不写日志；设置 `STORY_SESSION_LOG=1` 时向已有 `追踪/session-log.txt` 追加轻量会话日志 |
| `PostToolUse` | 检测到 `git commit` 后提示检查 README、AGENTS.md 或 `追踪/上下文.md` 是否需要同步 |

这些是 Codex 插件 hooks，不是 Claude 的 `.claude/hooks`。脚本入口为 `hooks/story-lifecycle-hook.cjs`。

## 升级到 v0.6.16 + 上游 main 同步

如果你已经在写作项目中运行过 `/story-setup`，升级 skill 后建议在项目根目录重新运行一次 `/story-setup`。本次同步将 `agents_version` 升级到 v15、`setup_skill_version` 升级到 `1.1.6`，用于刷新 `.codex/story-agents/`、`.codex/story-rules/` 和 `.codex/story-agent-references/`。

本仓库已同步上游 v0.6.16，并继续同步上游 main 在 v0.6.16 之后的更新，重点包括：

- **扫榜脚本实测修复**：番茄分批详情解析、点众书名/链接重写、七猫/刺猬猫链接回填、黑岩错误态细分，并补充全平台连通性自检和质量信号。
- **晋江详情页采集**：补充收藏、营养液、积分、字数、状态等公开指标，支持 `--detail-limit` / `--list-only` 控量。
- **番茄题材/标签扩采**：题材取 `categoryV2`，标签取简介开头 `【...】`，移除 SSR 无评分字段的错误声明。
- **写作与拆解修复**：长篇写作流程自动过滤破折号，规范化器不再误伤合法破折号；拆解管道补材料合法性语境。
- **prompt-cache 优化**：`story-deslop`、`narrative-writer`、`story-long-analyze` 减少提示词缓存未命中。
- **拆文到写作模块链**：长篇拆文新增「关键信息与扩写技法」「剧情/节奏.md」「剧情/情绪模块.md」等可复用写作模块，导入和日更流程会优先消费这些对标资产。
- **审查与写作规则**：补推理型一致性检查、自然分段、主语节奏、解释腔/上帝感/安排感识别与情绪烈度检查。
- **Codex 正文前置检查**：插件级 `PreToolUse` hook 会在首次创建正文时检查对应细纲/小节大纲；续写、改稿和导入迁移场景放行。
- **story-setup / story-review**：`agents_version` 升级到 v15，刷新相关 agent 模板和 reference bundle。
- **Codex lifecycle hook**：继续保留插件级 hook，不恢复上游项目内 hook 部署，不写入 `.claude/hooks` 或 `.claude/settings.local.json`。

Codex lifecycle hook 由本仓库插件机制加载，不由 `/story-setup` 写入用户项目目录。升级插件版本后，重新打开会话即可获得新版 hook 行为。

## 项目文件结构

长篇项目推荐结构：

```text
长篇/{书名}/
├── 设定/
├── 大纲/
├── 正文/
├── 对标/
│   └── {对标书名}/
│       ├── 原文/
│       ├── 角色/
│       ├── 剧情/
│       ├── 设定/
│       └── 拆文报告.md
├── 追踪/
│   ├── 上下文.md
│   ├── 伏笔.md
│   ├── 时间线.md
│   └── 角色状态.md
└── 参考资料/
```

短篇项目推荐结构：

```text
短篇/{标题}/
├── 正文.md
├── 小节大纲.md
├── 设定.md
├── 自检_{标题}.md
└── 对标/
```

`拆文库/` 是 analyze skill 的原始结构化产出，通常位于项目根目录；写作 skill 通过当前作品的 `对标/` 目录消费这些资产，并在缺失时回退读取 `拆文库/`。

## 本地安装

在 Windows + Git Bash 环境下，运行：

```bash
bash scripts/install-local-skills.sh
```

安装目录解析顺序：

1. `CODEX_SKILLS_DIR`
2. `$CODEX_HOME/skills`
3. `~/.codex/skills`

如果已存在同名 skill，需要覆盖更新时运行：

```bash
bash scripts/install-local-skills.sh --force
```

本仓库维护者的本地 Codex 数据目录是 `C:/CodexData`，不是通用默认目录；如需复现这个个人环境，使用：

```bash
CODEX_SKILLS_DIR=/c/CodexData/skills bash scripts/install-local-skills.sh --force
```

安装后建议重启或新开一个 Codex 会话，让 skill 发现列表刷新。可用以下命令检查本包 13 个 skill 是否完整可读；通用情况下把参数换成实际安装目录：

```bash
bash scripts/smoke-test-local-skills.sh /c/CodexData/skills
```

## 上游与许可

- 上游项目：[`worldwonderer/oh-story-claudecode`](https://github.com/worldwonderer/oh-story-claudecode)
- 上游许可证：MIT License
- 本仓库保留原项目 `LICENSE`，并在此基础上进行 Codex 适配。
- 本项目完全基于原项目，并使用 Codex 自动完成迁移修改。

## 贡献者与致谢

- 原项目作者 / 上游核心贡献者：[`worldwonderer`](https://github.com/worldwonderer)
- Codex 移植维护：`oh-story-codex contributors`

## 交流

- **Telegram 群**：<https://t.me/ohstoryclaudecode>，用于日常交流、踩坑和新功能讨论。
- **GitHub Discussions**：[提问 / 求助 / 分享用法](https://github.com/worldwonderer/oh-story-claudecode/discussions)，便于检索上游讨论。

## 发布描述建议

GitHub 仓库描述建议使用：

```text
非官方 Codex 移植版：基于 worldwonderer/oh-story-claudecode 的中文网文写作技能包
```

英文描述可使用：

```text
Unofficial Codex port of worldwonderer/oh-story-claudecode
```

## 转换说明

- 移除了 Claude/OpenClaw 专属 frontmatter 字段，例如 `version`、`metadata.openclaw`。
- 将 Claude 的 `CLAUDE.md` 项目模板迁移为 Codex 使用的 `AGENTS.md` 模板。
- 将 `.claude/agents` 的专用 agent 文件保留为 `.codex/story-agents` 参考提示词库；Codex 运行时不能自动注册 Claude 子代理。
- 将上游自动 hooks 改为 Codex 插件级生命周期 hooks，挂载在 `hooks/hooks.json`。
- 保留浏览器 CDP 和平台榜单采集脚本；这些脚本仍依赖 Node.js、Chrome 和 `agent-browser`。
- `story-cover` 原流程引用 GPT-Image API；在 Codex 中也可以改用当前会话可用的图像生成能力。

## 验证

```bash
bash scripts/static-check.sh
bash scripts/check-shared-files.sh
bash scripts/check-story-setup-deployment.sh
bash scripts/smoke-test-local-skills.sh
```

也可以直接运行 Codex 官方 skill 校验脚本：

```bash
python /c/CodexData/skills/.system/skill-creator/scripts/quick_validate.py skills/story
```
