# 升级指南

## 升级策略

| 策略 | 适用场景 | 风险 |
|------|----------|------|
| 覆盖部署 | 全新项目或无需保留自定义 | 低 |
| 合并部署 | 有自定义内容需保留 | 中 |
| 手动更新 | 只改特定文件 | 低 |

推荐：运行 `/story-setup` 重新部署，自动走合并策略。

## 文件分类

### 可安全覆盖

这些文件由 story-setup 管理，不含用户自定义内容：
- `.codex/story-agents/` — 所有 story agent 参考提示词
- `.codex/story-rules/` — 所有写作规则参考

### 需合并（不覆盖）

这些文件可能含用户自定义内容：
- `AGENTS.md` — 按 section 合并，用户独有 section 保留

### 不碰

这些文件完全由用户管理：
- `{书名}/追踪/上下文.md` — 用户写作上下文
- `{书名}/追踪/伏笔.md` — 用户伏笔追踪
- `.active-book` — 用户活跃书目

> Codex 插件级 lifecycle hooks 由本仓库 `.codex-plugin/plugin.json` 和 `hooks/hooks.json` 加载，不由 `story-setup` 写入用户项目目录。

## 版本检测

`.story-deployed` 文件记录部署版本：
- 无此文件 → 未部署，需全新安装
- `agents_version: 1` → 旧版，需重新部署以获取新版参考提示词
- `agents_version: 2` → 旧版，需重新部署以获取 story-explorer 参考提示词
- `agents_version: 3` → 旧版，需重新部署以获取 story-explorer 参考提示词
- `agents_version: 4` → 旧版，需重新部署以获取 v5 narrative-writer 参考提示词
- `agents_version: 5` → 旧版，需重新部署以统一短篇正文格式
- `agents_version: 6` → 旧版，需重新部署以获取日更续写规则修复
- `agents_version: 7` → 旧版，需重新部署以获取 agent 参考文件路径修复
- `agents_version: 8` → 当前版本

## 版本变更

### v2

- 4 个创作型参考提示词 + 1 个研究型参考提示词（story-architect, character-designer, narrative-writer, consistency-checker, story-researcher）
- 参考提示词引用 skill references 写作理论
- 4 条写作规则参考

### v3

- 新增 story-explorer 只读查询参考提示词（角色/伏笔/设定/进度查询，日更上下文快速加载）
- 6 个参考提示词总计（story-architect, character-designer, narrative-writer, consistency-checker, story-researcher, story-explorer）
- story-explorer 被 story-long-write、story-review、story 路由作为参考使用

### v4

- 新增 chapter-extractor 章节提取参考提示词
- 7 个参考提示词总计（story-architect, character-designer, narrative-writer, consistency-checker, story-researcher, story-explorer, chapter-extractor）

### v5

- 更新 narrative-writer 场景写法：使用“三维度织入”并按镜头断段控制段落密度
- 字数统计改为 Python 字符统计优先，`wc -m` 仅作 macOS/Linux 备选，提升 Windows + Codex 兼容性
- 已部署项目重新运行 `/story-setup` 后获取新版 story agent 参考提示词

### v6

- 统一 narrative-writer 参考提示词与主会话的短篇正文格式：固定写入 `正文.md`、小节标记统一、段落无空行、对话半角双引号。
- 短篇写作不再由 narrative-writer 创建长篇 `追踪/上下文.md`。

### v7

- 修复长篇 `/story-long-write 日更` 批量续写中的 continuation 规则：同一批次内“继续/续写/日更”保持在 daily workflow，不直接跳到正文续写。
- 修复伏笔缺口提示语义：正常开放伏笔（`未埋`/`已埋`）不是缺口；只有 `已过期` 或异常状态需要提示。
- Codex 插件级 lifecycle hook 由本仓库插件加载，不由 `/story-setup` 写入用户项目目录；升级本插件后重新打开会话即可使用新版 hook 行为。已部署项目重新运行 `/story-setup` 用于刷新 `.codex/story-agents/` 和 `.codex/story-rules/`。

### v8 (当前)

- 修复 story-review 及部署后的 reviewer agent 在项目根目录下读取参考文件时，只找裸文件名导致找不到 skill references 的问题。
- agent 模板新增参考文件路径规则：优先从本仓库 `skills/` 或 Codex 全局 skills 目录解析 `story-setup/references/agent-references/*.md` 规范路径，避免依赖当前工作目录且不跨 skill 引用 references。
- 已部署项目需重新运行 `/story-setup`，以覆盖 `.codex/story-agents/` 并获得新版参考文件路径规则。
