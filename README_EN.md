**English** | [中文](README.md)

# oh-story-codex

Unofficial Codex port of `worldwonderer/oh-story-claudecode`, a Chinese web novel writing skill pack. It keeps the original methodology for trend scanning, deconstruction, writing, review, AI tone removal, import, and cover generation, while converting skill metadata and project templates for Codex.

> This is an unofficial Codex port. It is not an official release maintained by the upstream author.

## Included Skills

| Skill | Purpose |
|---|---|
| `story` | Toolbox router that dispatches user intent to the matching writing workflow |
| `story-setup` | Initializes a Codex writing project and project-level `AGENTS.md` |
| `story-long-scan` | Long-form platform trend scanning and genre analysis |
| `story-long-analyze` | Long-form bestseller deconstruction, golden first chapters, and deep analysis |
| `story-long-write` | Long-form book setup, outlining, daily writing, and chapter revision |
| `story-short-scan` | Short-form platform trend scanning and market analysis |
| `story-short-analyze` | Short-form structure, emotion curve, twist, and hook analysis |
| `story-short-write` | Short-form ideation, section writing, and final polish |
| `story-deslop` | Detects and reduces AI-like prose patterns in Chinese web fiction |
| `story-review` | Multi-perspective story quality review |
| `story-import` | Reverse-imports an existing novel into a continuation-ready project structure |
| `story-cover` | Web novel cover prompt and image generation workflow |
| `browser-cdp` | Uses Chrome DevTools Protocol to reuse login sessions for page collection |

## Codex Usage

This repository is a Codex plugin directory. The plugin entry is `.codex-plugin/plugin.json`, and the skill directories are under `skills/`.

For local skill usage, copy the required skill directories into `$CODEX_HOME/skills/`. For plugin usage, keep the repository structure intact and load it through Codex's plugin mechanism.

Each `SKILL.md` keeps only the frontmatter required by Codex skill discovery: `name` and `description`. `agents/openai.yaml` provides UI metadata and does not drive the core workflow.

## Local Installation

On Windows with Git Bash:

```bash
bash scripts/install-local-skills.sh
```

Install directory resolution order:

1. `CODEX_SKILLS_DIR`
2. `$CODEX_HOME/skills`
3. `~/.codex/skills`

Use `--force` to overwrite existing skills:

```bash
bash scripts/install-local-skills.sh --force
```

The current maintainer's personal Codex data directory is `C:/CodexData`, which is not the generic default. To reproduce that local setup:

```bash
CODEX_SKILLS_DIR=/c/CodexData/skills bash scripts/install-local-skills.sh --force
```

After installation, restart Codex or open a new Codex session so the skill list refreshes. To smoke-test the 13 skills from this package:

```bash
bash scripts/smoke-test-local-skills.sh /c/CodexData/skills
```

## Upstream And License

- Upstream project: [`worldwonderer/oh-story-claudecode`](https://github.com/worldwonderer/oh-story-claudecode)
- Upstream license: MIT License
- This repository keeps the original `LICENSE` and adapts the project for Codex.
- This project is entirely based on the upstream project and was migrated with Codex.

## Contributors And Acknowledgments

- Original author / upstream core contributor: [`worldwonderer`](https://github.com/worldwonderer)
- Codex port maintenance: `oh-story-codex contributors`

## Suggested GitHub Description

```text
Unofficial Codex port of worldwonderer/oh-story-claudecode
```

Chinese description:

```text
非官方 Codex 移植版：基于 worldwonderer/oh-story-claudecode 的中文网文写作技能包
```

## Conversion Notes

- Removed Claude/OpenClaw-specific frontmatter fields such as `version` and `metadata.openclaw`.
- Migrated the Claude `CLAUDE.md` project template to Codex `AGENTS.md`.
- Kept the original `.claude/agents` role files as `.codex/story-agents` reference prompts. Codex does not automatically register Claude-style custom subagents.
- Kept browser CDP and platform ranking collection scripts. These still depend on Node.js, Chrome, and `agent-browser`.
- `story-cover` originally references GPT-Image API. In Codex, it can also use the image generation capability available in the current session.

## Validation

```bash
bash scripts/static-check.sh
bash scripts/check-shared-files.sh
bash scripts/smoke-test-local-skills.sh
```

You can also run Codex's official skill validator directly:

```bash
python /c/CodexData/skills/.system/skill-creator/scripts/quick_validate.py skills/story
```
