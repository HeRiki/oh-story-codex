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
    "Claude Code": "Codex",
    "OpenClaw": "Codex",
    "OpenCode": "Codex",
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
    " → `.opencode/agents/{agent}.md`": "",
    "、`.opencode/agents/{story-explorer|story-researcher}.md`": "",
    "，其次 `.opencode/agents/`": "",
    "其次检查 `.opencode/agents/`，再": "",
    "不存在时再检查 `.opencode/agents/`，再": "",
    "`、`.opencode/agents/`": "`",
    "{项目根}/.opencode/skills/{规范路径}`（Codex 项目内安装）": "{项目根}/.codex/skills/{规范路径}`（Codex 项目内安装）",
    "`{项目根}/.opencode/skills/story-setup/references/agent-references/{文件名}`": "`{项目根}/.codex/skills/story-setup/references/agent-references/{文件名}`",
    "CLAUDE.md": "AGENTS.md",
    "Agent(subagent_type": "spawn_agent(name",
    "subagent_type": "agent name",
    "spawn_agent(name:": "spawn_agent(name=",
    "spawn_agent(name= ": "spawn_agent(name=",
    'spawn_agent(role: "': 'spawn_agent(name="',
    'spawn_agent(role="': 'spawn_agent(name="',
    "Claude/Codex": "Codex",
    "Codex/Codex": "Codex",
    "Codex / Codex": "Codex",
    "Codex、Codex": "Codex",
    "Codex 和 Codex": "Codex",
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
