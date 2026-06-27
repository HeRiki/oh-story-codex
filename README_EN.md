**English** | [中文](README.md)

# oh-story-codex

Unofficial Codex port of `worldwonderer/oh-story-claudecode`, a Chinese web novel writing skill pack. It keeps the original methodology for trend scanning, deconstruction, writing, review, AI tone removal, import, and cover generation, while converting skill metadata and project templates for Codex.

> This is an unofficial Codex port. It is not an official release maintained by the upstream author.

## Core Approach

> **Tropes = deterministic emotional payoff**

The workflow follows a practical commercial-writing loop: scan trending charts, deconstruct pacing and reusable plot material, then recombine hooks, payoff, expectation management, and genre modules into the user's own story. The package is organized around reverse-engineering hits, modular plot reuse, layered story-state tracking, and human-AI collaboration.

## Included Skills

| Skill | Purpose |
|---|---|
| `story` | Toolbox router that dispatches user intent to the matching writing workflow and supports active-book switching |
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

## Demo

This Codex port keeps the synced demos to show deconstruction outputs and a continuation-ready imported writing project. Some demos include upstream-provided source backups or sample prose so the analyze/import/write workflow can be verified end to end.

Main files:

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

## Codex Usage

This repository is a Codex plugin directory. The plugin entry is `.codex-plugin/plugin.json`, and the skill directories are under `skills/`.

For local skill usage, copy the required skill directories into `$CODEX_HOME/skills/`. For plugin usage, keep the repository structure intact and load it through Codex's plugin mechanism.

Each `SKILL.md` keeps only the frontmatter required by Codex skill discovery: `name` and `description`. `agents/openai.yaml` provides UI metadata and does not drive the core workflow.

`story-setup` deploys 7 story-agent reference prompts into `.codex/story-agents/` and a local reference bundle into `.codex/story-agent-references/` inside a writing project. They are not Claude-style auto-registered subagents. Codex reads them as role instructions by default; use `spawn_agent` only when the user explicitly asks for multi-agent delegation.

| Reference prompt | Purpose |
|---|---|
| `story-architect` | Story architecture, main plot, worldbuilding, long-range foreshadowing |
| `character-designer` | Character design, relationships, motivation, growth arcs |
| `narrative-writer` | Prose drafting, continuation, chapter revision |
| `consistency-checker` | Setting consistency, foreshadowing, timeline checks |
| `story-researcher` | Research and reference collection |
| `story-explorer` | Read-only project and progress lookup |
| `chapter-extractor` | Deep deconstruction Stage 2 chapter summary, plot point, and character extraction |

Plugin lifecycle hooks are defined in `hooks/hooks.json` and loaded through the `hooks` field in `.codex-plugin/plugin.json`.

| Hook | Purpose |
|---|---|
| `PreToolUse` | Before `git commit`, reminds maintainers to sync settings, outlines, tracking files, and docs |
| `SessionStart` | Loads `追踪/上下文.md` for initialized story projects and reports missing settings, outline, prose, foreshadowing, or timeline files |
| `UserPromptSubmit` | Reminds Codex to read project context before handling story-writing prompts |
| `Stop` | Does not write logs by default; when `STORY_SESSION_LOG=1`, appends a lightweight session log to existing `追踪/session-log.txt` |
| `PostToolUse` | After `git commit`, reminds maintainers to check README, AGENTS.md, or `追踪/上下文.md` updates |

These are Codex plugin hooks, not Claude `.claude/hooks`. The script entry point is `hooks/story-lifecycle-hook.cjs`.

## Upgrading to v0.6.18

If you have already run `/story-setup` inside a writing project, run `/story-setup` again from the project root after updating this skill pack. This sync bumps `agents_version` to v16 and `setup_skill_version` to `1.1.7`, refreshing `.codex/story-agents/`, `.codex/story-rules/`, and `.codex/story-agent-references/`.

This repository has synced upstream v0.6.17/v0.6.18 plus the current upstream `main` updates included in this port. Main changes:

- **AI-pattern detection**: adds `check-ai-patterns.js` for deterministic checks of Chinese negative-to-positive AI prose patterns across `story-deslop`, `story-review`, and long/short writing file workflows.
- **Prose naturalness**: refreshes dialogue voice checks, style-drift checks, first-use anchors for new terms/settings, concrete character-count expression checks, and punctuation rhythm rules.
- **Cover workflow**: syncs pen-name collection and crop fallback guidance while keeping the Codex image-generation entrypoint.
- **Version checks**: adds `skills/story/VERSION`; `story` can check the upstream release and report version differences. It does not auto-install the upstream package.
- **Codex prose preflight**: the plugin-level `PreToolUse` hook still checks for matching outlines before first prose creation. This version also handles Windows/Git Bash drive-style absolute paths such as `/d/...`.
- **story-setup / story-review**: `agents_version` is now v16, refreshing related agent templates and the reference bundle. Stale deployments fall back to solo review and suggest rerunning `/story-setup`.
- **Codex lifecycle hooks**: remain plugin-level hooks. This port does not restore upstream project-local hook deployment and does not write `.claude/hooks` or `.claude/settings.local.json`.

Codex lifecycle hooks are loaded by this repository's plugin mechanism, not written into the user's project by `/story-setup`. Reopen the session after upgrading the plugin to use the new hook behavior.

## Project File Structure

Recommended long-form structure:

```text
Long/{Book Title}/
├── Settings/
├── Outlines/
├── Prose/
├── Benchmark/
│   └── {Benchmark Book}/
│       ├── Source/
│       ├── Characters/
│       ├── Plotlines/
│       ├── Settings/
│       └── Report.md
├── Tracking/
│   ├── Context.md
│   ├── Foreshadowing.md
│   ├── Timeline.md
│   └── Character_Status.md
└── References/
```

Recommended short-form structure:

```text
Short/{Title}/
├── Prose.md
├── Section_outline.md
├── Settings.md
├── Self-check.md
└── Benchmark/
```

`拆文库/` is the source-of-truth deconstruction library produced by analyze skills, usually at project root. Writing skills consume those assets through the current work's `对标/` directory and fall back to `拆文库/` when needed.

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

## Community

- **Telegram**: <https://t.me/ohstoryclaudecode> for chat, troubleshooting, and feature discussion.
- **GitHub Discussions**: [ask questions, get help, share workflows](https://github.com/worldwonderer/oh-story-claudecode/discussions).

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
- Adapted upstream automatic hooks into Codex plugin lifecycle hooks in `hooks/hooks.json`.
- Kept browser CDP and platform ranking collection scripts. These still depend on Node.js, Chrome, and `agent-browser`.
- `story-cover` originally references GPT-Image API. In Codex, it can also use the image generation capability available in the current session.

## Validation

```bash
bash scripts/static-check.sh
bash scripts/check-shared-files.sh
bash scripts/check-story-setup-deployment.sh
bash scripts/smoke-test-local-skills.sh
```

You can also run Codex's official skill validator directly:

```bash
python /c/CodexData/skills/.system/skill-creator/scripts/quick_validate.py skills/story
```
