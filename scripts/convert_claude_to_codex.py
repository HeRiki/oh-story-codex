#!/usr/bin/env python3
"""Convert copied Claude/OpenClaw skill files into Codex skill metadata."""

from __future__ import annotations

from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]


REPLACEMENTS = {
    "Claude Code": "Codex",
    "OpenClaw": "Codex",
    "AskUserQuestion": "直接向用户确认",
    'Skill("skill-name")': "显式使用对应的 Codex skill，或在本线程按该 skill 的流程执行",
    "Claude 单次输出": "单次输出",
    "Claude单次输出": "单次输出",
}


def render_frontmatter(name: str, description: str) -> str:
    lines = ["---", f"name: {name}"]
    description = description.strip("\n")
    if "\n" in description:
        lines.append("description: |")
        lines.extend(f"  {line}" for line in description.splitlines())
    else:
        dumped = yaml.safe_dump(
            description,
            allow_unicode=True,
            default_style='"',
            width=10_000,
        ).strip()
        lines.append(f"description: {dumped}")
    lines.append("---")
    return "\n".join(lines)


def convert_skill(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return

    parts = text.split("---", 2)
    if len(parts) != 3:
        return

    _, frontmatter, body = parts
    data = yaml.safe_load(frontmatter) or {}
    name = data.get("name", path.parent.name)
    description = data.get("description", "")
    if not isinstance(description, str):
        description = str(description)

    converted = render_frontmatter(name, description) + body
    for source, target in REPLACEMENTS.items():
        converted = converted.replace(source, target)
    path.write_text(converted, encoding="utf-8", newline="\n")


def main() -> None:
    for skill_file in sorted((ROOT / "skills").glob("*/SKILL.md")):
        convert_skill(skill_file)


if __name__ == "__main__":
    main()
