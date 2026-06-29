#!/usr/bin/env python3
"""Generate Codex custom-agent TOML templates from Codex-facing agent markdown.

The markdown files under story-setup/references/templates/agents remain the
source of truth for role text. Codex expects standalone TOML files with at
least name, description, and `developer_instructions`; this script performs a
deterministic conversion.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

READ_ONLY_AGENTS = {"chapter-extractor", "consistency-checker", "story-explorer"}
NICKNAMES = {
    "chapter-extractor": ["Chapter Extractor", "Scene Splitter"],
    "character-designer": ["Character Designer", "Voice Crafter"],
    "consistency-checker": ["Consistency Checker", "Continuity Guard"],
    "narrative-writer": ["Narrative Writer", "Prose Crafter"],
    "story-architect": ["Story Architect", "Plot Architect"],
    "story-explorer": ["Story Explorer", "Lore Scout"],
    "story-researcher": ["Story Researcher", "Source Scout"],
}


def parse_frontmatter(text: str) -> tuple[dict[str, str], str]:
    if not text.startswith("---\n"):
        raise ValueError("missing frontmatter")
    end = text.find("\n---\n", 4)
    if end < 0:
        raise ValueError("unterminated frontmatter")
    raw = text[4:end]
    body = text[end + len("\n---\n") :].lstrip()
    data: dict[str, str] = {}
    lines = raw.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip() or line.lstrip().startswith("#"):
            i += 1
            continue
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*):(?:\s*(.*))?$", line)
        if not m:
            i += 1
            continue
        key, value = m.group(1), (m.group(2) or "").rstrip()
        if value == "|":
            block: list[str] = []
            i += 1
            while i < len(lines):
                nxt = lines[i]
                if nxt and not nxt.startswith((" ", "\t")):
                    break
                block.append(nxt[2:] if nxt.startswith("  ") else nxt.lstrip())
                i += 1
            data[key] = "\n".join(block).strip()
            continue
        data[key] = value.strip().strip('"').strip("'")
        i += 1
    return data, body


def toml_basic_string(value: str) -> str:
    # Use a multi-line basic string so Chinese instructions and Markdown remain readable.
    escaped = value.replace('\\', '\\\\').replace('"""', '\\\"\\\"\\\"')
    return f'"""\n{escaped.rstrip()}\n"""'


def toml_inline_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def toml_list(values: list[str]) -> str:
    return "[" + ", ".join(toml_inline_string(v) for v in values) + "]"


_REF_BLOCK_RE = re.compile(
    r"读取参考文件时，\*\*严格按以下顺序直接 Read，禁止先用 Glob/Grep 搜索\*\*：\n"
    r"(?:\d+\. `\{项目根\}/[^`]+story-setup/references/agent-references/[^`]+`\n?)+"
)


def _codex_reference_order(match: "re.Match[str]") -> str:
    return (
        "读取参考文件时，**严格按以下顺序直接读取，禁止先做全局文件/文本搜索**：\n"
        "1. `{项目根}/.codex/skills/story-setup/references/agent-references/{文件名}`\n"
        "2. `{项目根}/.codex/story-agent-references/{文件名}`\n"
        "3. `{项目根}/skills/story-setup/references/agent-references/{文件名}`\n"
    )


def adapt_body_for_codex(body: str, name: str) -> str:
    """Translate caller terminology to Codex custom-agent wording."""
    adapted = body.replace("subagent_type", "agent_type")
    adapted = re.sub(
        r"spawn_agent\(name=\"([^\"]+)\"\)",
        r'Codex custom agent request (agent_type="\1")',
        adapted,
    )
    adapted = _REF_BLOCK_RE.sub(_codex_reference_order, adapted)
    adapted = re.sub(r"story-setup/references/agent-references/([A-Za-z0-9_-]+\.md)", r"\1", adapted)
    adapted = adapted.replace("GPT/Claude 默认偏", "模型默认偏")
    adapted = adapted.replace("Claude 默认偏", "模型默认偏")
    adapted = adapted.replace("WebSearch/webReader", "联网搜索/网页读取")
    adapted = adapted.replace("WebSearch / webReader", "联网搜索 / 网页读取")
    adapted = adapted.replace("WebSearch", "联网搜索")
    adapted = adapted.replace("webReader", "网页读取")
    adapted = re.sub(r"\bGlob\b", "文件匹配", adapted)
    adapted = re.sub(r"\bGrep\b", "文本搜索", adapted)
    adapted = re.sub(r"\bRead\b", "读取文件", adapted)
    return (
        adapted.rstrip()
        + "\n\n---\n\n"
        + "Codex adaptation notes:\n"
        + f"- Codex callers should request this custom agent with `agent_type: \"{name}\"` when the current runtime exposes project-local custom agents.\n"
        + "- If Codex reports `unknown agent_type` or the custom-agent registry is unavailable, the parent workflow must fall back to solo/direct execution and report the fallback instead of failing.\n"
        + "- Stay within this agent's role boundary; escalate adjacent work back to the parent agent.\n"
        + "- Use project-local story references first: `.codex/skills/story-setup/references/agent-references/`, then `.codex/story-agent-references/`, then repository `skills/`.\n"
        + "- Do not assume non-Codex tool names or frontmatter fields exist.\n"
    )


def convert_file(src: Path, dst_dir: Path) -> Path:
    text = src.read_text(encoding="utf-8")
    meta, body = parse_frontmatter(text)
    name = meta.get("name") or src.stem
    description = meta.get("description", "").strip()
    if not description:
        raise ValueError(f"{src}: missing description")
    instructions = adapt_body_for_codex(body, name)
    out = [
        f"name = {toml_inline_string(name)}",
        f"description = {toml_basic_string(description)}",
        f"nickname_candidates = {toml_list(NICKNAMES.get(name, [name]))}",
    ]
    if name in READ_ONLY_AGENTS:
        out.append('sandbox_mode = "read-only"')
    out.append(f"developer_instructions = {toml_basic_string(instructions)}")
    dst = dst_dir / f"{name}.toml"
    dst.write_text("\n".join(out) + "\n", encoding="utf-8", newline="\n")
    return dst


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source",
        default="skills/story-setup/references/templates/agents",
        help="Claude agent template directory",
    )
    parser.add_argument(
        "--dest",
        default="skills/story-setup/references/codex/agents",
        help="Codex TOML output directory",
    )
    args = parser.parse_args()
    src_dir = Path(args.source)
    dst_dir = Path(args.dest)
    if not src_dir.is_dir():
        raise FileNotFoundError(f"source agent template directory not found: {src_dir}")
    dst_dir.mkdir(parents=True, exist_ok=True)
    generated = [convert_file(path, dst_dir) for path in sorted(src_dir.glob("*.md"))]
    generated_names = {path.name for path in generated}
    managed_names = {f"{name}.toml" for name in NICKNAMES}
    missing_managed = managed_names - generated_names
    if missing_managed:
        raise RuntimeError(
            "missing generated managed agent TOML(s): "
            + ", ".join(sorted(missing_managed))
        )
    for stale in dst_dir.glob("*.toml"):
        if stale.name in managed_names and stale.name not in generated_names:
            stale.unlink()
    print(f"Generated {len(generated)} Codex agent files in {dst_dir}")
    for path in generated:
        print(f"- {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
