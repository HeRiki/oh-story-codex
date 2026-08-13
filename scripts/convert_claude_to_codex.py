#!/usr/bin/env python3
"""Convert copied Claude/OpenClaw skill files into Codex-facing text."""

from __future__ import annotations

from pathlib import Path
import json

try:
    import yaml
except ModuleNotFoundError:
    yaml = None


ROOT = Path(__file__).resolve().parents[1]


REPLACEMENTS = {
    "Claude Code / OpenCode / Codex / ZCode / OpenClaw 是内置适配目标；NarraFork、Web AI、自定义 Agent 等能读取项目文件的环境，可按本 skill 执行长篇流程。检查专业 agent 时按 `.claude/agents/{agent}.md` → `.opencode/agents/{agent}.md` → `.codex/agents/{agent}.toml` 查找；找不到、Codex 返回 `unknown agent_type`，或检测到 `.zcode/`（ZCode 3.3.4 不执行项目 custom agents）时，直接 solo/direct 执行并报告 fallback。": "Codex 是内置适配目标。检查专业 agent 时按 `.codex/story-agents/{agent}.md` → `.codex/agents/{agent}.toml` 查找；只有文件缺失、Codex 返回 `unknown agent_type`，或当前运行时未暴露 custom-agent registry 时才降级为 solo/direct，并报告 fallback。",
    "Agent 兼容性：检查专业 agent 是否可用时，按 `.claude/agents/{agent}.md` → `.opencode/agents/{agent}.md` → `.codex/agents/{agent}.toml` 的顺序查找。Codex 原生子代理调用优先使用同名 `agent_type`；如果当前 Codex 运行时返回 `unknown agent_type` 或未暴露 custom-agent registry，必须降级为 solo/direct。检测到 `.zcode/` 时同样直接 solo/direct，因为 ZCode 3.3.4 不执行项目 custom agents；报告 `Fallback: project custom agents unavailable -> solo`。Claude/OpenCode 兼容面保留 `subagent_type`。": "Agent 兼容性：检查专业 agent 时按 `.codex/story-agents/{agent}.md` → `.codex/agents/{agent}.toml` 查找。Codex 原生子代理调用优先使用同名 `agent_type`；只有文件缺失、运行时返回 `unknown agent_type`，或未暴露 custom-agent registry 时才降级为 solo/direct，并报告 `Fallback: project custom agents unavailable -> solo`。",
    "Codex CLI 中优先使用 `$story-*` 或 `/skills` 触发；Claude Code / OpenCode 继续使用 `/story-*`；OpenClaw 可用 `/skill story-*` 或自然语言点名 skill。下表以 slash command 展示，Codex 可将 `/story-long-write` 等价替换为 `$story-long-write`，OpenClaw 可将其等价替换为 `/skill story-long-write`。": "Codex 中优先使用 `$story-*` 或 `/skills` 触发。下表以 slash command 展示；在 Codex 里可将 `/story-long-write` 等价替换为 `$story-long-write`。",
    "如果能明确匹配，直接调用对应 skill（Claude/OpenCode 可用 `Skill(\"skill-name\")` 或 slash command；Codex 用 `$skill-name` / `/skills`；OpenClaw 用 `/skill skill-name` 或自然语言点名）": "如果能明确匹配，显式使用对应的 Codex skill，或在本线程按该 skill 的流程执行",
    "且 `.claude/agents/{story-explorer|story-researcher}.md`、`.opencode/agents/{story-explorer|story-researcher}.md` 或 `.codex/agents/{story-explorer|story-researcher}.toml` 存在": "且 `.codex/story-agents/{story-explorer|story-researcher}.md` 或 `.codex/agents/{story-explorer|story-researcher}.toml` 存在",
    "（优先检查 `.claude/agents/`，其次检查 `.opencode/agents/`，再检查 `.codex/agents/`）": "（优先检查 `.codex/story-agents/`，其次检查 `.codex/agents/`）",
    "（优先检查 `.claude/agents/` 下的 `": "（优先检查 `.codex/story-agents/` 下的 `",
    "` 是否存在；不存在时再检查 `.opencode/agents/`，再不存在时检查 `.codex/agents/`）": "` 是否存在；不存在时检查 `.codex/agents/`）",
    "`.claude/agents/": "`.codex/story-agents/",
    ".claude/agents/": ".codex/story-agents/",
    " → `.opencode/agents/` → `.codex/agents/`": " → `.codex/agents/`",
    " → `.opencode/agents/`，再检查 `.codex/agents/`": " → `.codex/agents/`",
    "`.codex/story-agents/chapter-extractor.md` → `.opencode/agents/chapter-extractor.md` → `.codex/agents/chapter-extractor.toml`": "`.codex/story-agents/chapter-extractor.md` → `.codex/agents/chapter-extractor.toml`",
    "用户自写（Claude Code 可代写）": "用户自写（Codex 可代写）",
    "## OpenCode 环境注意事项": "## Codex 环境注意事项",
    "opencode 没有后台执行命令行的工具": "某些 Codex 运行环境没有后台执行命令行的工具",
    "在 opencode 中按 `ESC`": "在 Codex 中按 `ESC`",
    "Windows / DeepSeek / Claude Code 组合下": "Windows / Codex 组合下",
    "调用方（Claude / 上层脚本）": "调用方（Codex / 上层脚本）",
    "优先检查 `.codex/story-agents/`，检查 `.codex/agents/`；三个目录任一存在即视为已部署": "检查 `.codex/story-agents/` 或 `.codex/agents/`；任一目录存在即视为已部署",
    "full 必需：Codex 为 `story-architect.md`、`character-designer.md`、`narrative-writer.md`、`consistency-checker.md`；Codex 为同名 `.toml`": "full 必需：参考提示词目录包含 `story-architect.md`、`character-designer.md`、`narrative-writer.md`、`consistency-checker.md`，或 custom-agent 目录包含同名 `.toml`",
    "lean 必需：Codex 为 `story-architect.md`、`consistency-checker.md`；Codex 为同名 `.toml`": "lean 必需：参考提示词目录包含 `story-architect.md`、`consistency-checker.md`，或 custom-agent 目录包含同名 `.toml`",
    "      - **Codex agent（`.opencode/agents/`）**：文件名即 agent 名（Codex 不要求在 frontmatter 中写 `name:`），读取 frontmatter 确认 `mode: subagent` 和 `permission` 字段存在且可解析即可；frontmatter 缺失或不可解析视为 malformed。\n": "",
    "1. `{项目根}/skills/{规范路径}`（Codex 项目内安装）\n2. `{项目根}/.codex/skills/{规范路径}`（Codex 项目内安装）\n3. `{项目根}/.codex/skills/{规范路径}`（Codex 项目内安装）\n4. `{项目根}/.codex/skills/{规范路径}`（Codex 项目内安装）\n5. `{项目根}/skills/{规范路径}`（Codex / generic 部署，也是本仓库开发环境）\n6. `{项目根}/.agents/skills/{规范路径}`（Codex 扫描的项目 skill root，通常是指向 `skills/` 的 symlink）\n7. 当前运行时加载本 skill 的目录，或其可访问的全局 skill 搜索路径中同名 `{skill-name}/...` 目录": "1. 当前运行时加载本 skill 的目录。\n2. `{项目根}/.codex/skills/{规范路径}`（story-setup 只复制必要的 agent reference bundle）。\n3. `{项目根}/.agents/skills/{规范路径}` 或 `{项目根}/skills/{规范路径}`（Codex 项目级 skill 安装）。\n4. `CODEX_HOME/skills/{规范路径}`；本机个人安装默认为 `C:\\\\CodexData\\\\skills/{规范路径}`。",
    "> 靠前几层不存在是正常的，不是部署损坏。`/story-setup` 只在 Codex 的 `skills/` 和 Codex / generic 的 `skills/` 下整份复制 skill；Codex 项目部署不复制 skill 本体，本 skill 由 Codex 从 skill root 加载，references 就在其中，通常命中第 6 或第 7 层。不要手工把 `references/` 复制进 `.codex/skills/`——手工副本不受 story-setup 管理，升级后会静默变旧。": "> 项目部署不复制 skill 本体；当前 skill 目录和 `CODEX_HOME/skills/` 是主来源。`.codex/skills/story-setup/references/agent-references/` 仅由 story-setup 管理 agent reference bundle，不要手工复制整份 references。",
    "gh release view --json tagName,name,url -R worldwonderer/oh-story-claudecode": "gh release view --json tagName,name,url -R HeRiki/oh-story-codex",
    "https://api.github.com/repos/worldwonderer/oh-story-claudecode/releases/latest": "https://api.github.com/repos/HeRiki/oh-story-codex/releases/latest",
    "https://github.com/worldwonderer/oh-story-claudecode/releases": "https://github.com/HeRiki/oh-story-codex/releases",
    "https://github.com/worldwonderer/oh-story-claudecode/blob/main/CHANGELOG.md": "https://github.com/HeRiki/oh-story-codex/blob/master/CHANGELOG.md",
    "不要用本地旧版 setup 降级覆盖": "不要用本地旧版 setup 降级覆盖；先更新 oh-story-codex",
    "先更新 oh-story-claudecode": "先更新 oh-story-codex",
    "3. **识别 ZCode 能力边界**：如果当前运行于 ZCode 且项目使用 `.zcode/`，ZCode 3.3.4 不执行项目/plugin custom agents；不要因为磁盘上存在其他端的 agent 文件就尝试同名 spawn，直接降级 `solo` 并报告 `Fallback: project custom agents unavailable -> solo`。": "3. **识别 Codex 能力边界**：项目存在 `.codex/` 本身不是降级条件。只有 agent 文件缺失、运行时返回 `unknown agent_type`，或当前运行时未暴露 custom-agent registry 时，才降级 `solo` 并报告 `Fallback: project custom agents unavailable -> solo`。",
    "`/story-setup` 后新开会话；大于 25 时额外提示先更新 oh-story-claudecode，不要用本地旧版 setup 降级覆盖。": "`$story-setup` 后新开会话；大于 25 时额外提示先更新 oh-story-codex，不要用本地旧版 setup 降级覆盖。",
    "```python\nspawn_agent(\n  agent_type: ": "```text\nspawn_agent(\n  agent_type=",
    "  prompt: ": "  prompt=",
    "spawn_agent(agent_type: ": "spawn_agent(agent_type=",
    "，prompt: ": ", prompt=",
    "agent_type: \"": "agent_type=\"",
    "sonnet 升级重试": "更强推理配置升级重试",
    "- 如果 `.story-deployed` 的 `target_cli` 包含 `zcode`，项目 agents 缺失是 ZCode 3.3.4 的预期状态：不要提示重复部署，直接以串行 solo/direct 进入分析并报告 fallback。\n": "",
    "；先更新 oh-story-codex；先更新 oh-story-codex": "",
    "Claude Code / OpenCode / Codex / ZCode / OpenClaw": "Codex",
    "Claude/OpenCode/Codex/ZCode/OpenClaw": "Codex",
    "Claude/OpenCode/Codex/ZCode/OpenClaw/generic": "Codex",
    "Claude/OpenCode/Codex": "Codex",
    "OpenCode / OpenClaw / generic": "Codex",
    "OpenCode/ZCode": "Codex",
    "Claude Code": "Codex",
    "OpenClaw": "Codex",
    "OpenCode": "Codex",
    "ZCode": "Codex",
    "Reasonix": "Codex",
    "reasonix": "codex",
    "workbuddy": "Codex",
    "当前 Claude 部署": "当前 Codex 部署",
    "直接 Read 当前 Codex 部署的 canonical 路径": "直接读取当前 Codex 部署的 canonical 路径",
    "禁止先用 Glob/Grep 搜索": "禁止先做全局文件/文本搜索",
    "AskUserQuestion": "直接向用户确认",
    "WebSearch/webReader": "联网搜索/网页读取",
    "WebSearch / webReader": "联网搜索 / 网页读取",
    "WebSearch": "联网搜索",
    "webReader": "网页读取",
    'Skill("skill-name")': "显式使用对应的 Codex skill，或在本线程按该 skill 的流程执行",
    "Claude 单次输出": "单次输出",
    "Claude单次输出": "单次输出",
    ".claude/agents": ".codex/story-agents",
    ".claude/hooks": ".codex plugin lifecycle hooks",
    ".claude/rules": ".codex/story-rules",
    ".claude/settings.local.json": "hooks/hooks.json",
    ".claude/skills/": "skills/",
    ".opencode/agents/{agent}.md` → ": "",
    ".zcode/agents/{agent}.md` → ": "",
    " → `.opencode/agents/{agent}.md`": "",
    " → `.zcode/agents/{agent}.md`": "",
    "、`.opencode/agents/{story-explorer|story-researcher}.md`": "",
    "，其次 `.opencode/agents/`": "",
    "，其次 `.zcode/agents/`": "",
    "其次检查 `.opencode/agents/`，再": "",
    "其次检查 `.zcode/agents/`，再": "",
    "不存在时再检查 `.opencode/agents/`，再": "",
    "不存在时再检查 `.zcode/agents/`，再": "",
    "`、`.opencode/agents/`": "`",
    "`、`.zcode/agents/`": "`",
    "{项目根}/.opencode/skills/{规范路径}`（Codex 项目内安装）": "{项目根}/.codex/skills/{规范路径}`（Codex 项目内安装）",
    "{项目根}/.zcode/skills/{规范路径}`（Codex 项目内安装）": "{项目根}/.codex/skills/{规范路径}`（Codex 项目内安装）",
    "`{项目根}/.opencode/skills/story-setup/references/agent-references/{文件名}`": "`{项目根}/.codex/skills/story-setup/references/agent-references/{文件名}`",
    "CLAUDE.md": "AGENTS.md",
    ".zcode/skills/": "skills/",
    ".zcode/commands/": ".codex/commands/",
    ".zcode/hooks": ".codex/hooks",
    ".zcode": ".codex",
    "Agent(\n  agent name: ": "spawn_agent(\n  agent_type: ",
    "Agent(subagent_type": "spawn_agent(agent_type",
    "subagent_type": "agent name",
    "spawn_agent(name: ": "spawn_agent(agent_type=",
    "spawn_agent(name:": "spawn_agent(agent_type=",
    "spawn_agent(name= ": "spawn_agent(agent_type=",
    "spawn_agent(name=": "spawn_agent(agent_type=",
    'spawn_agent(role: "': 'spawn_agent(agent_type="',
    'spawn_agent(role="': 'spawn_agent(agent_type="',
    "Claude/Codex": "Codex",
    "Codex/Codex": "Codex",
    "Codex / Codex": "Codex",
    "Codex、Codex": "Codex",
    "Codex 和 Codex": "Codex",
    "Codex/Codex/Codex": "Codex",
    "Codex/Codex/Codex/Codex": "Codex",
    "Codex / Codex / Codex": "Codex",
    "→ ``.codex": "→ `.codex",
    "Codex 兼容面保留 `agent name`": "Codex 中按当前可用工具字段调用",
    "Codex 兼容面使用 `agent name`": "Codex 参考提示词路径使用 `name`",
    "同模型（haiku）重试": "同配置重试",
    "升级到 sonnet 重试": "升级到更强推理配置重试",
    'model: "sonnet",            # 显式覆盖 frontmatter 的 haiku': '# 如当前 Codex 支持子代理推理配置，可切换到更强推理配置',
    "haiku 首次通过": "默认配置首次通过",
    "haiku 失败 + 同模型 retry 通过": "默认配置失败 + 同配置 retry 通过",
    "质量失败 + sonnet retry 通过": "质量失败 + 更强推理配置 retry 通过",
    "sonnet retry 仍失败": "更强推理配置 retry 仍失败",
    "retry_sonnet": "retry_stronger_config",
    "主线程会用 sonnet 覆盖本 agent 的默认 haiku": "主线程会改用更强推理配置",
    "npx skills add worldwonderer/oh-story-claudecode -y -g": "从本仓 Codex 移植版仓库同步或安装最新版本",
    "项目根目录下的 `skills/` 或 `skills/` 拼接解析": "项目根目录下的 `skills/` 拼接解析，其次从 Codex 全局 skills 目录查找",
    "先尝试 `skills/{规范路径}`，再尝试 `skills/{规范路径}`，最后用": "先尝试 `skills/{规范路径}`，再用",
}


def render_frontmatter(name: str, description: str) -> str:
    lines = ["---", f"name: {name}"]
    description = description.strip("\n")
    if "\n" in description:
        lines.append("description: |")
        lines.extend(f"  {line}" for line in description.splitlines())
    else:
        if yaml is not None:
            dumped = yaml.safe_dump(
                description,
                allow_unicode=True,
                default_style='"',
                width=10_000,
            ).strip()
        else:
            dumped = json.dumps(description, ensure_ascii=False)
        lines.append(f"description: {dumped}")
    lines.append("---")
    return "\n".join(lines)


def load_frontmatter(frontmatter: str) -> dict[str, str]:
    if yaml is not None:
        data = yaml.safe_load(frontmatter) or {}
        return data if isinstance(data, dict) else {}

    data: dict[str, str] = {}
    lines = frontmatter.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line or line.startswith((" ", "\t")) or ":" not in line:
            i += 1
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value == "|":
            block = []
            i += 1
            while i < len(lines):
                current = lines[i]
                if current and not current.startswith((" ", "\t")) and ":" in current:
                    break
                block.append(current[2:] if current.startswith("  ") else current.lstrip())
                i += 1
            data[key] = "\n".join(block).rstrip("\n")
            continue
        if value:
            data[key] = value.strip("\"'")
        i += 1
    return data


def convert_skill(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return

    parts = text.split("---", 2)
    if len(parts) != 3:
        return

    _, frontmatter, body = parts
    data = load_frontmatter(frontmatter)
    name = data.get("name", path.parent.name)
    description = data.get("description", "")
    if not isinstance(description, str):
        description = str(description)

    converted = render_frontmatter(name, description) + body
    for source, target in REPLACEMENTS.items():
        converted = converted.replace(source, target)
    path.write_text(converted, encoding="utf-8", newline="\n")


def convert_markdown(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    converted = text
    for source, target in REPLACEMENTS.items():
        converted = converted.replace(source, target)
    if converted != text:
        path.write_text(converted, encoding="utf-8", newline="\n")


def convert_agent_template(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        convert_markdown(path)
        return

    parts = text.split("---", 2)
    if len(parts) != 3:
        convert_markdown(path)
        return

    _, frontmatter, body = parts
    data = load_frontmatter(frontmatter)
    name = data.get("name", path.stem)
    description = data.get("description", "")
    if not isinstance(description, str):
        description = str(description)

    converted = render_frontmatter(name, description) + body
    for source, target in REPLACEMENTS.items():
        converted = converted.replace(source, target)
    path.write_text(converted, encoding="utf-8", newline="\n")


def main() -> None:
    for markdown_file in sorted((ROOT / "skills").glob("**/*.md")):
        convert_markdown(markdown_file)
    for agent_file in sorted((ROOT / "skills/story-setup/references/templates/agents").glob("*.md")):
        convert_agent_template(agent_file)
    for skill_file in sorted((ROOT / "skills").glob("*/SKILL.md")):
        convert_skill(skill_file)


if __name__ == "__main__":
    main()
