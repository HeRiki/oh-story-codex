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

本仓库继续保留已同步的 demo，用于展示拆文产物、导入工程和 Dashboard 文件树。部分 demo 按上游原样包含原文备份或示例正文，用于验证拆文、导入和浏览链路。

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

其中长篇 demo 的 `追踪/` 仍是历史展示数据，不符合当前 schema 4 事务协议，不能直接作为续写检查点。实际项目必须通过 `$story-import` 迁移或用 `tracking_commit.py init` 建立 `追踪/_tracking-state.json`，不要手工把旧 Markdown 追踪文件当成权威状态。

## Dashboard 工作台

使用 `$story dashboard`，或在写作工作区执行下面的等价命令，即可打开本地工作台：

```bash
node "<story-skill-dir>/scripts/dashboard-server.mjs" --root "<workspace>" --open
```

工作台支持拆文库与长短篇项目的按需目录树、文件名搜索、Markdown 安全预览、白名单文本编辑、mtime 冲突保护保存和确认删除。保存使用同目录临时文件原子替换；Windows 覆盖已有文件时由 `.NET File.Replace` 保留失败前原稿。服务只允许绑定本机回环地址，不提供局域网或公网模式。

## Codex 使用方式

本仓库本身就是一个 Codex 插件目录，入口在 `.codex-plugin/plugin.json`，技能目录在 `skills/`。作为本地技能使用时，可以把需要的单个 skill 目录复制到 `$CODEX_HOME/skills/`；作为插件使用时，保留当前目录结构并通过 Codex 插件机制加载。

每个 `SKILL.md` 的 frontmatter 只保留 `name` 和 `description`，适配 Codex 的 skill 发现规则。`agents/openai.yaml` 提供 UI 元数据，不参与核心工作流。

`story-setup` 会把 7 个 story agent 参考提示词部署到写作项目的 `.codex/story-agents/`，把 Codex custom agents 部署到 `.codex/agents/*.toml`，并把 agent 参考资料副本部署到 `.codex/story-agent-references/` 与 `.codex/skills/story-setup/references/agent-references/`。Codex custom agents 需要项目 `.codex/` 被 trust，并在新会话中才会稳定可用；不可用时各写作 skill 会降级 solo/direct。

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
| `PreToolUse` | 创建正文前检查对应细纲；检测到 `git commit` 时提醒确认设定、大纲、追踪事务和文档是否同步 |
| `SessionStart` | 会话开始/恢复时按 `.active-book` 读取当前书的 schema 4 权威状态及 `追踪/上下文.md`，提示项目缺口、异常伏笔或追踪迁移需求 |
| `UserPromptSubmit` | 用户提交写作相关提示时，提醒优先读取项目上下文和追踪文件 |
| `Stop` | 默认不写日志；设置 `STORY_SESSION_LOG=1` 时向已有 `追踪/session-log.txt` 追加轻量会话日志 |
| `PostToolUse` | 检测到 `git commit` 后提示检查 README、AGENTS.md 或 `追踪/上下文.md` 是否需要同步 |

这些是 Codex 插件 hooks，脚本入口为 `hooks/story-lifecycle-hook.cjs`。`story-setup` 还会按需部署项目级 `.codex/hooks.json`、`.codex/hooks/story_codex_hook.py`、`.codex/hooks/run-story-hook.sh` 与 `.codex/hooks/run-story-hook.cmd`，用于项目随附的正文前置检查、compact 上下文提示和 Stop 阶段正文兜底复扫。

## 升级到 v0.7.5

本仓库已同步上游 v0.7.1-v0.7.5，以及 v0.7.5 tag 后截至 `1eae178` 的 Codex 可用通用修改；非 Codex runtime、manifest 和 hooks 没有引入。仓库发布版本保持 `0.7.5`，不会因为同步 tag 后 main 而虚构更高版本。

如果写作项目已经运行过 `$story-setup`，更新本 skill 包后必须在项目根目录重跑一次 `$story-setup`，然后新开 Codex 会话。本次部署契约是 `agents_version: 25`、`setup_skill_version: 1.2.7`，会刷新 `.codex/story-agents/`、`.codex/agents/`、项目级 hooks、rules 和 reference bundle。

本轮重点变化：

- **单一权威追踪事务**：`追踪/_tracking-state.json` 升级为 schema 4 唯一权威；上下文状态卡、伏笔、作者真相/读者已知时间线、角色状态和逐章记录都由 `tracking_commit.py` 确定性派生。
- **派生视图修复**：`tracking_commit.py rebuild --project {书项目根}` 可从权威 state 重建派生视图，不改 state、revision 或逐章记录。
- **旧项目必须迁移**：已有正文但没有 `_tracking-state.json` 的长篇项目会 fail closed；使用 `$story-import` 的旧追踪迁移流程，只重建 `追踪/`，不必重跑正文、设定、大纲或全书拆解。
- **Story Dashboard**：新增只绑定回环地址的本地工作台，支持懒加载目录树、跨未展开目录搜索、安全预览、冲突感知保存和确认删除。
- **长篇热路径精简**：开书、单章和日更流程拆到 `workflow-setup.md`、`workflow-chapter.md`、`workflow-daily.md` 按需加载，并增加文档预算守卫。
- **Codex Hooks 加固**：项目发现限制深度并排除符号链接；正文目标识别覆盖重定向、嵌套 shell、heredoc、复制/移动和 `apply_patch`；新增章节顺序、状态修订和派生视图一致性检查，同时保留 Windows/Git Bash 路径归一化与双 launcher。
- **写作与拆文规则更新**：同步正文元信息隔离、自然句长、章尾反总结体、拆文叙事化摘要、精选原文证据、超长作品分批聚合和跨批审查合同。
- **扫榜采集加固**：补齐起点、番茄、晋江、七猫、黑岩等采集字段、参数校验、数据质量摘要和 Windows 路径兼容。
- **版本与合同**：`.codex-plugin/plugin.json` 和 `skills/story/VERSION` 为 `0.7.5`，`scripts/current-contract.json` 记录 `agents_version: 25`。

Codex 插件 lifecycle hook 由本仓库插件机制加载；项目级 hook 由 `$story-setup` 部署。更新插件后重新打开会话可获得新版插件 hook，重跑 `$story-setup` 并新开会话可刷新项目级 hook 和 custom agents。

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
│   ├── _tracking-state.json
│   ├── 上下文.md
│   ├── 伏笔.md
│   ├── 逐章记录/
│   ├── 角色状态/
│   │   └── {角色名}.md
│   └── 时间线/
│       ├── 作者真相.md
│       └── 读者已知.md
└── 参考资料/
```

`_tracking-state.json` 是唯一结构化权威，其余 `追踪/` 文件都是派生视图，只能通过 `tracking_commit.py init/commit` 整体生成，并用 `tracking_commit.py check` 验证；不要分别手改。

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
- 将上游角色 agent 转为 `.codex/story-agents` 参考提示词库，并生成 `.codex/agents/*.toml` 供 Codex 原生 custom agents 注册。
- 将上游自动 hooks 改为 Codex 插件级生命周期 hooks，挂载在 `hooks/hooks.json`。
- 保留浏览器 CDP 和平台榜单采集脚本；这些脚本仍依赖 Node.js、Chrome 和 `agent-browser`。
- `story-cover` 原流程引用 GPT-Image API；在 Codex 中也可以改用当前会话可用的图像生成能力。

## 验证

```bash
bash scripts/static-check.sh
bash scripts/check-shared-files.sh
bash scripts/check-story-setup-deployment.sh
bash scripts/smoke-test-local-skills.sh
npm test
```

也可以直接运行 Codex 官方 skill 校验脚本：

```bash
python /c/CodexData/skills/.system/skill-creator/scripts/quick_validate.py skills/story
```
