# scripts/ —— 仓库开发脚本索引

这些是开发本仓库（skill 套件本体）用的**守卫 / 测试 / 代码生成**脚本，**不是** skill 运行时脚本（运行时脚本在各 skill 自己的 `scripts/` 下，如 `story-deslop/scripts/check-ai-patterns.js`，跨 skill 字节同步）。

- 绝大多数由 CI 自动跑（`.github/workflows/cross-platform.yml`）。提交前本地一把梭的完整命令见 [CONTRIBUTING.md](../CONTRIBUTING.md)「CI 检查」。
- **改名 / 移动任一脚本**，要同步改 `.github/workflows/*.yml`、`CONTRIBUTING.md`、本文件，以及调用它的兄弟脚本（见下方「何时跑」里的调用关系）。

## 静态守卫（check-*）

| 脚本 | 检查什么 | 何时跑 |
|---|---|---|
| `static-check.sh` | Skill 结构、frontmatter、引用路径、死文件、references 交叉引用（结构总闸） | CI |
| `check-shared-files.sh` | 跨 skill 同名 reference/脚本副本字节一致 | CI |
| `check-story-setup-deployment.sh` | story-setup 部署/运行时回归（慢，>2min） | CI |
| `check-hook-regex-sync.sh` | `detect-story-gaps.sh` 伏笔状态检测行为 | CI（也被 test-prose-net-parity 调） |
| `check-python-invocation.sh` | 技能文档禁止裸调 `python3`（须 python3→python→py 探测） | CI（也被 test-charcount-portable 调） |
| `check-codex-adapter.sh` | Codex 插件适配层：plugin manifest、根 hook、Codex agent TOML、项目 hooks 锚点 | CI（调 generate-codex-agents.py 验生成确定性） |

## 测试回归（test-*）

| 脚本 | 测什么 | 何时跑 |
|---|---|---|
| `test-ai-patterns.sh` | 确定性 AI 句式检测器 `check-ai-patterns.js` 回归 | CI |
| `test-degeneration.sh` | 模型退化检测器 `check-degeneration.js` 回归 | CI |
| `test-codex-hooks.sh` | Codex hook 合成 stdin/stdout 契约、正文前置检查、Stop 兜底与连续性提示 | CI |
| `test-charcount-portable.sh` | 跨平台字符统计命令在三平台 + Windows 的正确性 | CI（调 check-python-invocation） |

## 代码生成 / 同步

| 脚本 | 干什么 | 何时跑 |
|---|---|---|
| `generate-codex-agents.py` | 从 Codex 角色提示词模板生成 Codex `.toml` agents | 改 agent 模板后手动跑；被 check-codex-adapter 调验确定性 |

> 改了 `skills/story-setup/references/templates/agents/*.md`，必须重跑 `python scripts/generate-codex-agents.py` 并提交结果，否则适配层 CI 红。详见 [CONTRIBUTING.md](../CONTRIBUTING.md)。
