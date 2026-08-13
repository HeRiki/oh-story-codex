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

This Codex port keeps the synced demos to show deconstruction outputs, imported project files, and the Dashboard tree. Some demos include upstream-provided source backups or sample prose for analyze, import, and browsing verification.

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

The long-form demo's `追踪/` directory is historical display data and does not satisfy the current schema 4 transaction protocol. Do not use it directly as a continuation checkpoint. Real projects must migrate through `$story-import` or initialize `追踪/_tracking-state.json` with `tracking_commit.py init`.

## Story Dashboard

Run `$story dashboard`, or use the equivalent command from a writing workspace:

```bash
node "<story-skill-dir>/scripts/dashboard-server.mjs" --root "<workspace>" --open
```

The local Dashboard provides lazy project/library trees, filename search, safe Markdown preview, allowlisted text editing, mtime conflict protection, and confirmed deletion. Saves use same-directory atomic replacement; on Windows, `.NET File.Replace` preserves the original manuscript when replacement fails. It only accepts loopback bindings and has no LAN or public-network mode.

## Codex Usage

This repository is a Codex plugin directory. The plugin entry is `.codex-plugin/plugin.json`, and the skill directories are under `skills/`.

For local skill usage, copy the required skill directories into `$CODEX_HOME/skills/`. For plugin usage, keep the repository structure intact and load it through Codex's plugin mechanism.

Each `SKILL.md` keeps only the frontmatter required by Codex skill discovery: `name` and `description`. `agents/openai.yaml` provides UI metadata and does not drive the core workflow.

`story-setup` deploys 7 story-agent reference prompts into `.codex/story-agents/`, Codex custom agents into `.codex/agents/*.toml`, and local reference bundles into `.codex/story-agent-references/` plus `.codex/skills/story-setup/references/agent-references/`. Codex custom agents require the project `.codex/` layer to be trusted and are most reliable after a fresh session; when unavailable, writing skills fall back to solo/direct execution.

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
| `PreToolUse` | Checks the matching outline before creating prose; before `git commit`, reminds maintainers to sync settings, outlines, tracking transactions, and docs |
| `SessionStart` | Uses `.active-book` to load the current book's schema 4 authority plus `追踪/上下文.md`, then reports project gaps, abnormal foreshadowing, or migration requirements |
| `UserPromptSubmit` | Reminds Codex to read project context before handling story-writing prompts |
| `Stop` | Does not write logs by default; when `STORY_SESSION_LOG=1`, appends a lightweight session log to existing `追踪/session-log.txt` |
| `PostToolUse` | After `git commit`, reminds maintainers to check README, AGENTS.md, or `追踪/上下文.md` updates |

These are Codex plugin hooks. The script entry point is `hooks/story-lifecycle-hook.cjs`. `story-setup` can also deploy project-level `.codex/hooks.json`, `.codex/hooks/story_codex_hook.py`, `.codex/hooks/run-story-hook.sh`, and `.codex/hooks/run-story-hook.cmd` for outline-before-prose checks, compact context hints, and Stop-time prose backstop scans.

## Upgrading to v0.7.5

This repository now includes Codex-usable shared changes from upstream v0.7.1 through v0.7.5 and post-tag upstream main through `1eae178`. Non-Codex runtimes, manifests, and hooks are intentionally excluded. The package version remains `0.7.5`; syncing post-tag main does not invent a later release number.

If a writing project already ran `$story-setup`, rerun it from the project root after updating this pack, then start a fresh Codex session. The current deployment contract is `agents_version: 25` and `setup_skill_version: 1.2.7`, refreshing `.codex/story-agents/`, `.codex/agents/`, project hooks, rules, and reference bundles.

Key changes:

- **Single-authority tracking transactions**: schema 4 `追踪/_tracking-state.json` is the only authority. `tracking_commit.py` deterministically renders the context card, foreshadowing, author/reader timelines, character snapshots, and per-chapter records.
- **Derived-view repair**: `tracking_commit.py rebuild --project <book-root>` reconstructs derived views from the authority without changing state, revision, or chapter records.
- **Required legacy migration**: a long-form project with prose but no `_tracking-state.json` fails closed. Use `$story-import` legacy tracking migration; it rebuilds only `追踪/` and does not require reprocessing prose, settings, outlines, or the whole novel.
- **Story Dashboard**: a loopback-only local workbench with lazy trees, unloaded-directory search, safe preview, conflict-aware saves, and confirmed deletion.
- **Smaller long-form hot path**: setup, chapter, and daily workflows now load on demand through `workflow-setup.md`, `workflow-chapter.md`, and `workflow-daily.md`, guarded by document budgets.
- **Stronger Codex hooks**: bounded project discovery, symlink exclusion, write-target parsing for redirection/nested shell/heredoc/copy/move/`apply_patch`, chapter-order and state-revision checks, and derived-view consistency checks. Windows/Git Bash path normalization and dual launchers remain supported.
- **Writing and analysis updates**: prose metadata isolation, natural sentence rhythm, anti-summary endings, narrative chapter summaries, selected source evidence, bounded aggregation for very long works, and cross-batch review contracts.
- **Scanner hardening**: richer fields, parameter validation, data-quality summaries, and Windows path fixes across the supported ranking collectors.
- **Version contract**: `.codex-plugin/plugin.json` and `skills/story/VERSION` are `0.7.5`; `scripts/current-contract.json` records `agents_version: 25`.

Plugin lifecycle hooks are loaded by this repository's plugin mechanism; `$story-setup` deploys project hooks. Reopen Codex after updating the plugin, and rerun `$story-setup` plus start a new session to refresh project hooks and custom agents.

## Project File Structure

Recommended long-form structure (directory names are the actual on-disk names):

```text
长篇/{Book Title}/
├── 设定/
├── 大纲/
├── 正文/
├── 对标/
├── 追踪/
│   ├── _tracking-state.json
│   ├── 上下文.md
│   ├── 伏笔.md
│   ├── 逐章记录/
│   ├── 角色状态/{Character}.md
│   └── 时间线/
│       ├── 作者真相.md
│       └── 读者已知.md
└── 参考资料/
```

`_tracking-state.json` is the only structured authority. Every other file under `追踪/` is a derived view generated as a unit by `tracking_commit.py init/commit` and verified with `tracking_commit.py check`; do not edit them independently.

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
- Adapted upstream role agents into `.codex/story-agents` reference prompts and generated `.codex/agents/*.toml` for native Codex custom-agent registration.
- Adapted upstream automatic hooks into Codex plugin lifecycle hooks in `hooks/hooks.json`.
- Kept browser CDP and platform ranking collection scripts. These still depend on Node.js, Chrome, and `agent-browser`.
- `story-cover` originally references GPT-Image API. In Codex, it can also use the image generation capability available in the current session.

## Validation

```bash
bash scripts/static-check.sh
bash scripts/check-shared-files.sh
bash scripts/check-story-setup-deployment.sh
bash scripts/smoke-test-local-skills.sh
npm test
```

You can also run Codex's official skill validator directly:

```bash
python /c/CodexData/skills/.system/skill-creator/scripts/quick_validate.py skills/story
```
