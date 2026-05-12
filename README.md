# oh-story-codex

Codex 版中文网文写作技能包，由 `worldwonderer/oh-story-claudecode` 转换而来。它保留原包的扫榜、拆文、写作、审查、去 AI 味、导入和封面生成方法论，并把 skill metadata 转成 Codex 可识别格式。

> 这是非官方 Codex 移植版，不代表原作者发布或维护的官方版本。

## 包含的 Skills

| Skill | 用途 |
|---|---|
| `story` | 工具箱路由入口，根据用户意图分发到具体写作流程 |
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

## Codex 使用方式

本仓库本身就是一个 Codex 插件目录，入口在 `.codex-plugin/plugin.json`，技能目录在 `skills/`。作为本地技能使用时，可以把需要的单个 skill 目录复制到 `$CODEX_HOME/skills/`；作为插件使用时，保留当前目录结构并通过 Codex 插件机制加载。

每个 `SKILL.md` 的 frontmatter 只保留 `name` 和 `description`，适配 Codex 的 skill 发现规则。`agents/openai.yaml` 提供 UI 元数据，不参与核心工作流。

## 上游与许可

- 上游项目：[`worldwonderer/oh-story-claudecode`](https://github.com/worldwonderer/oh-story-claudecode)
- 上游许可证：MIT License
- 本仓库保留原项目 `LICENSE`，并在此基础上进行 Codex 适配。

如果发布到自己的 GitHub 仓库，请把仓库描述写成“非官方 Codex 移植版”或类似措辞，避免让使用者误以为这是原作者官方仓库。

## 转换说明

- 移除了 Claude/OpenClaw 专属 frontmatter 字段，例如 `version`、`metadata.openclaw`。
- 将 Claude 的 `CLAUDE.md` 项目模板迁移为 Codex 使用的 `AGENTS.md` 模板。
- 将 `.claude/agents` 的专用 agent 文件保留为 `.codex/story-agents` 参考提示词库；Codex 运行时不能自动注册 Claude 子代理。
- 保留浏览器 CDP 和平台榜单采集脚本；这些脚本仍依赖 Node.js、Chrome 和 `agent-browser`。
- `story-cover` 原流程引用 GPT-Image API；在 Codex 中也可以改用当前会话可用的图像生成能力。

## 验证

```bash
bash scripts/static-check.sh
bash scripts/check-shared-files.sh
```

也可以直接运行 Codex 官方 skill 校验脚本：

```bash
python /c/CodexData/skills/.system/skill-creator/scripts/quick_validate.py skills/story
```
