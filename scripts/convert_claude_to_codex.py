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
    "CLAUDE.md": "AGENTS.md",
    "Agent(subagent_type": "spawn_agent(name",
    "subagent_type": "agent name",
    "spawn_agent(name:": "spawn_agent(name=",
    "spawn_agent(name= ": "spawn_agent(name=",
    'spawn_agent(role: "': 'spawn_agent(name="',
    'spawn_agent(role="': 'spawn_agent(name="',
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
