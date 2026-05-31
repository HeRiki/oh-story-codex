# Changelog

All notable changes to this project will be documented in this file.

## v0.6.13

> 同步上游 v0.6.13：write references 一致性修复、抽象概念落地化、同 skill 去重、商业核心方法命名修正与 agent 模板枚举漂移修复

### 改进

- **写作 references 落地化**：同步 plot-emotion-system、plot-frameworks、plot-core-methods、emotional-arc-design、outline-structure-theory、style-craft、short genre references 等上游修订，补真实网文例子并删除空泛公式、审美黑话和难执行比喻。
- **同 skill 去重**：权力博弈对话、角色状态模板、五幕式、阵营手牌法等重复块改为指向同 skill 内唯一资料源，降低后续维护漂移。
- **命名修正**：`story-long-write/references/style-commercial-theory.md` 改名为 `commercial-core-methods.md`，使文件名与“卖点/商业策略”内容匹配。
- **一致性修复**：短篇反转信息差阈值统一到 writing-workflow 三档，对话占比统一 45-65%，workflow-revision Step3 编号和 long-write 锚点名对齐正文。
- **F1 地图分层**：明确“新手村四势力”与“换地图三势力”是分层策略，不是设定矛盾，并补充变现/资源闭环提醒。

### Bug 修复

- **agent 模板枚举漂移**：`story-architect` 反转类型补齐认知/无反转，`character-designer` 关系命名对齐 `character-relations.md`。

### Codex 适配

- `story-setup` 升级到 `agents_version: 11`、`setup_skill_version: 1.1.2`，提示已部署项目重新运行 `/story-setup` 刷新 `.codex/story-agents/` 与 reference bundle。
- `story-review` stale deployment 检查同步升级到 v11。
- 保留 Codex 插件级 lifecycle hook，不同步上游 `.claude-plugin`、ClawHub 发布 workflow、`.claude/hooks`、`.claude/settings.local.json` 或 `CLAUDE.md` 部署。

## v0.6.12

> 同步上游 v0.6.10-v0.6.12：选题决策、长篇拆文/文风修正、短篇 output contract、女频长篇 playbook、术语白话化与工程守卫

### 新功能

- **story-long-scan**：新增持久 `选题决策.md`，记录能爆的原因、市场验证、差异化定位、可行性高/中/低、失败风险和验证动作。
- **story-long-analyze**：Stage 5 拆文汇总后可回填 `选题决策.md` 中对应选题的“能爆的原因”，将扫榜假设与拆文验证串起来。
- **story-long-write / story-short-write**：新增按主题快速定位索引，接入 `cross-book-recall.md`、`reversal-toolkit.md` 七类反转、短篇 `output-contract.md` 与女频写作 playbook。
- **story-long-write**：新增长篇女频 `female-audience-writing.md`，覆盖卷级感情节奏、多平台篇幅定位和长线骨架题材。

### 改进

- **story-setup**：`agents_version` 升级到 v10，`setup_skill_version` 升级到 `1.1.1`；刷新 7 个 story agent 参考提示词、reference bundle 和流程衔接说明。
- **story-review**：stale deployment 判断升级到 v10，并补充与写作、拆文、去 AI 味流程的衔接。
- **story-deslop**：同步上游 rubric 收紧，去除 AI 味时更强调证据、密度和自然段落节奏。
- **术语白话化**：清理上游新增的抽象术语和自造比喻，统一改为 Codex 版中文说明中的直白判断词。
- **采集脚本**：同步刺猬猫、晋江、七猫、点众、黑岩采集脚本的错误处理、失败提示和部分落盘逻辑。

### Codex 适配

- 保留 Codex 插件级 lifecycle hook，不恢复上游 `.claude/hooks`、`.claude/settings.local.json` 或 `CLAUDE.md` 部署。
- `story-setup` 继续部署 `AGENTS.md`、`.codex/story-agents/`、`.codex/story-rules/`、`.codex/story-agent-references/` 和 `.story-deployed`。
- `scripts/check-story-setup-deployment.sh` 与 `scripts/static-check.sh` 升级污染守卫，确保 skill 内不残留 Claude/OpenClaw 运行时字段。
- 保留 demo 不带小说原文的策略。

## v0.6.9

> 同步上游 v0.6.9：story-setup v9 reference bundle、review fallback、cover/CDP 脚本增强

### 改进

- **story-setup**：`agents_version` 升级到 v9，部署契约补充机械可检查清单，明确 `AGENTS.md`、`.codex/story-agents/`、`.codex/story-rules/`、`.codex/story-agent-references/`、上下文模板和 `.story-deployed` 的 source/target/merge/validation 规则。
- **story-setup**：新增 agent reference bundle canonical 副本：`genre-readers.md`、`genre-writing-formulas.md`、`emotional-methods.md`、`style-combat-face.md`。
- **story-review**：新增 stale deployment 检查；已部署项目版本小于 v9 时自动降级 solo，并提示重新运行 `/story-setup`。参考文件不可读时使用内置 rubric fallback，不再中断审查。
- **story-cover**：更新 GPT-Image-2 调用说明，区分文生图与图生图，移除旧 `response_format` 参数，增强错误处理和提示词落盘。
- **browser-cdp**：启动脚本新增 `--detect-only`、`--yes`、`--reset`、`--profile`，在非 TTY 下未获同意不会静默结束用户常规 Chrome。

### Bug 修复

- **chapter-extractor**：不再引用外部 `output-templates.md`，输出格式严格遵循自身「输出格式」章节。
- **story-format**：删除“章节之间用 `---` 分隔”的旧规则，改为禁止正文片段使用水平分隔线，与 narrative-writer 保持一致。
- **Codex lifecycle hook**：Stop 事件默认不再创建 `session-log.txt`；只有设置 `STORY_SESSION_LOG=1` 且已有 `追踪/` 时才追加轻量日志。
- **Hook 检查**：`check-hook-regex-sync.sh` 增加普通 `状态` 表头 fixture，锁定正常开放伏笔不报警。

### Codex 适配

- 新增 `scripts/check-story-setup-deployment.sh`，校验 story-setup 没有恢复旧运行时项目内 hooks/settings 部署，且插件级 hooks 仍由 `.codex-plugin/plugin.json` 加载。
- 保留 Codex 插件级 lifecycle hook，不恢复上游项目内 hook 部署。
- 保留 demo 不带小说原文的策略。

## v0.6.8

> story-import 重构 + skill 自包含化 + 起点扫榜与 story-review 参考路径修复

### 改进

- **story-import**：按篇幅自动分流。长篇走 story-long-analyze 完整拆解 + 长篇结构迁移；短篇走 story-short-analyze + 短篇结构迁移（单文件 `正文.md`，不产 `追踪/`、`大纲/` 等长篇专属目录）。判定优先级：用户声明 > 章节结构 > 字数兜底。
- **story-import**：长篇新增「角色状态反推」算法，从拆书产物反推 `追踪/角色状态.md`，补齐 story-long-write 日更准备层依赖。
- **story-import**：调用 story-long-analyze 时自动越过 Stage 1 停靠点，以「完整拆解、一次跑完、不要停下询问」模式驱动，确保 Stage 2-5 全套产物落地。
- **story-import**：迁移所需模板内联到本 skill references，清除跨 skill `../` 路径依赖。
- **story-setup**：`agents_version` 升级到 v8；部署后的 `.codex/story-agents/` 使用 `story-setup/references/agent-references/*.md` 规范路径，避免裸文件名和跨 skill references。

### Bug 修复

- 修复 story-review reviewer 读取 `quality-checklist.md` 等参考文件时按当前目录解析导致找不到的问题，统一走 `story-review/references/...` 规范路径。
- 修复起点中文网扫榜在 PC 站触发风控页时无法采集的问题；`qidian-rank-scraper.js` 默认改为移动端 SSR pageContext 抓取，并保留 CAPTCHA/CDP 回退。

### Codex 适配

- 保留 Codex 插件级 lifecycle hook，不恢复上游 `.claude/hooks` 部署。
- 保留 demo 不带小说原文的策略；未同步上游 `demo/拆文库-盘龙/原文/原文.txt`。

## v0.6.7

> 拆书 skill 重构：长篇单管道 + 短篇去模式化

### 改进

- **story-long-analyze**：快速/深度双模式合并为单一拆解管道。Stage 0+1 跑完黄金三章后产出 `快速预览.md` 并停靠，确认后从 Stage 2 续跑，不重跑已完成阶段。
- **story-long-analyze**：质量阈值、分块策略统一归 `material-decomposition.md`；管道运维内容拆出到 `pipeline-ops.md`。
- **story-short-analyze**：标准/精细双档收敛为单一全量拆解管道。
- **story-short-analyze**：质量阈值收敛到唯一权威文件；管道阶段术语对齐为 Stage 体系；新增原文备份前置步骤。
- 黄金三章深度拆解产物由单文件拆为三个单章文件 `第N章_深度拆解.md`。
- 同步更新 story-long-write、story-import、chapter-extractor 参考提示词中的拆书术语与文件名引用。

### Bug 修复

- 修复 `story-short-write` 指向「自检模式 / 拆文模式」的悬空引用。
- 修复短篇拆书情节节点密度在多处文件给出不一致数值的问题，统一到唯一权威字数分档表。

## v0.6.6

> 日更续写稳定性 + Codex lifecycle hook 伏笔降噪

### Bug 修复

- 修复长篇 `/story-long-write 日更` 在同一批次内用户回复“继续”时可能跳出 `workflow-daily.md`、直接进入正文续写的问题。
- 修复日更流程偶发绕过真实项目文件、依赖聊天记忆写作的问题：每章开始前必须确认读取本轮 workflow 内的细纲、上一章正文、上下文、伏笔、时间线和角色状态/设定。
- 修复 Codex `SessionStart` lifecycle hook 把正常开放伏笔（`未埋` / `已埋`）当成问题提示的问题；现在只提示 `已过期` 或异常状态。
- 修复 `workflow-daily.md` 中裸 `SKILL.md` section 描述被 static-check 误判为断裂 section 引用的问题。

### 改进

- **story-long-write**：日更批量写作中，“继续 / 续写 / 日更”统一解释为继续当前 daily workflow，不重新进入场景选择，也不跳过状态筛选和意图确认。
- **workflow-daily**：正常批量执行时不再逐章询问“是否继续”；仅在细纲缺失、章节号冲突、请求范围超过已有细纲、用户要求改大纲/追踪等真实阻塞时暂停确认。
- **伏笔处理**：日更流程只处理本轮新增、推进、回收的增量伏笔；全量伏笔审计只由 `/story-review` 或用户明确要求触发。
- **story-setup**：`agents_version` 升级到 v7；既有项目重新运行 `/story-setup` 可刷新 `.codex/story-agents/` 和 `.codex/story-rules/`，Codex lifecycle hook 由插件加载。
- **CI/脚本**：`check-hook-regex-sync.sh` 从静态正则覆盖检查升级为行为级 fixture 校验，验证正常开放状态不报警、`已过期` 和异常状态报警。

## v0.6.5

> 写作去 AI 味密度修复 + 对标路径说明统一

### 修复

- **story-short-write / story-long-write**: 正文写作从旧“三层展开”改为“三维度织入”，避免同一动作/情绪被拆成多段重复描写。
- **story-short-write / story-long-write**: 新增镜头断段、手机阅读密度和输出前密度重排规则，避免三维度织入后一段到底。
- **story-short-write / story-long-write / story-deslop**: 字数统计优先使用 Python 字符统计，`wc -m` 仅作 macOS/Linux 备选，禁止 `wc -c` 和模型估算。
- **story-deslop**: 将重复描写去重纳入 Gate C/D，不再额外堆叠专项流程。

### 改进

- **story-setup**: `agents_version` 升级到 v5，`narrative-writer` 参考提示词同步新版场景写法、段落密度和跨平台字数统计规则。
- **story-short-write**: 统一短篇 `对标/` 与 `拆文库/` 路径说明：项目根 `拆文库/` 为原始产出，短篇目录 `对标/` 为当前作品引用视图。
- **story-long-write / chapter-extractor / story-long-analyze**: 长篇情节点密度统一为 150-200 字/个情节点，每章下限 10 个、上限 40 个。

## v0.6.4

> 产线思路统一：核心思路集成 + 文件系统 + 准备层

### 新功能

- 新增 **state-tracking.md** 状态追踪协议文件（long-write / short-write 双 skill 共享）：最简记忆包提取逻辑（当前状态 / 历史因果 / 世界约束）和角色状态快照格式。

### 改进

- **story-long-write**: 新增“核心方法”section，按“先定情绪、验证过的模式、模块组装、只加载必需信息”组织长篇写作流程。
- **story-long-write**: 单章写作增加准备层：状态筛选、模块召回、指令确认，并新增 `追踪/角色状态.md` 更新规则。
- **story-long-write**: 文件结构图升级，`对标/` 支持角色、剧情、设定结构化子目录，并支持从 `拆文库/` 回退读取。
- **story-short-write**: 新增精简版“核心方法”、短篇 `对标/` 引用视图和逐场景准备层。
- **README / README_EN**: 同步项目文件结构、拆文库/对标关系和状态追踪说明，保留 Codex 移植版定位。

## v0.6.3

> 引用完整性修复 + CI static-check 增强

### Bug 修复

- **story-long-write**: `genre-writing-formulas.md` 引用了不存在的 `genre-writing-techniques.md`，改为正确的 `style-craft.md`
- **story-long-write**: `format-and-structure.md` section 引用 `设计任务第 4 步` 在 long-write SKILL.md 中不存在，改为 `Phase 3 细纲`
- **story-short-analyze**: 补充缺失的 `anti-ai-writing.md` 和 `banned-words.md`（从 story-deslop 复制）

### CI 增强 (static-check.sh)

- **Check 6 收紧**: `references/` 下的反引号引用限制在 skill 内解析，防止跨 skill 断裂引用静默通过
- **Check 7 新增**: 裸 .md 文件名检测（非反引号、非链接、非代码块），不存在的文件报 FAIL，存在的报 WARN
- **Check 8 新增**: SKILL.md section 引用验证（三级匹配：子串 → 空格前缀剥离 → 字符级 fallback），断裂的 section 引用报 FAIL
- 脚本注释更新，准确描述新增检查项和 Codex 污染检查

## v0.6.2

> story-short-analyze skill v2.1.0

### 新功能

- 新增 **material-decomposition.md** 短篇拆解方法论：情节节点提取、爆点分析、写作手法（POV/对话/时间/信息/意象）、节奏分析、人物功能评估、共鸣分析（9层）
- story-short-analyze 升级为三件套架构（SKILL.md + material-decomposition.md + output-templates.md），对齐长篇拆文体系深度
- 新增**故事核**提取（一句话概括核心梗）
- 新增**爆点性/话题性**分析
- 新增**共鸣分析**（9层共鸣：情感/价值观/经历/社会现象/文化/普世价值/哲学思考/情感深度/人物深度）
- 新增**人物分类**（主人公/主动人物/被动人物/功能人物）

### 改进

- 短篇拆文管道从模糊 Phase 描述升级为 5 阶段管道表（Phase 2-6，含输入/输出/完成标志）
- 情节节点提取：密度公式（200-300字/个，15-60个全文）、6种节点类型、情绪标记（-9~+9）
- 爆点分析：6维度（铺垫/积累/延迟/爆发点/余波/印象）+ 期待感分析
- 写作手法：POV策略（含切换检测）、对话手法（占比/潜台词率/模式识别）、信息控制矩阵、意象追踪
- 人物功能标签（7种）、内在矛盾提取、弧线记录、人物分类（主动/被动人物）、关系演变追踪
- 可选模块：同类对比、平台适配评估（知乎/番茄/七猫）、详细节奏分析
- 质量门控：情节节点覆盖≥90%、情感曲线100%、写作手法≥5项、人物100%、共鸣≥3层
- 精细/标准双模式路由
- 术语全面对齐行业标准（故事核/爆点/共鸣/主动人物被动人物等）
- 新增**拆解思路**章节：核心原则（故事核驱动/读者视角/可借鉴性/爆点为中心/共鸣决定传播）+ 分析顺序 + 每阶段核心问题 + 拆解心态
- 新增分析维度：套娃反转质量检验、伏笔式反转、称呼变化追踪、主题意象群、重读发现、弹幕/评论互动、反差萌、倒计时框架、双视角叙事、双主人公结构
- 新增报应设计细分（主角设局 vs 反派自毁）、甜宠/喜剧类五维替代维度（反差萌浓度+甜度曲线）
- 新增灵活分节说明、反转密度异常检测、BE结尾评估标准（意难平≥8）、期待感分析
- **术语去抽象化**：清理 9 个自造词（心酸双峰/甜度阶梯/弹幕元叙事/反差萌循环/隐性反转/被动报应自循环/意象系统/二次阅读设计/称呼操控式），回归已有概念和日常描述
- 标杆拆文 demo：《我爸死后，我成了他的影子拳手》（套娃反转式，4层嵌套+5人物+12节点情感曲线）

## v0.6.1

### 新功能

- 新增 **chapter-extractor** 章节提取参考提示词：客观白描铁律、动态密度公式（3-40范围）、100+项泛称黑名单（8类），支持 Codex 深度拆文逐章提取
- story-long-analyze 管线重构：故事框架识别、两步法剧情聚合、3层置信度孤立情节兜底
- 管线鲁棒性：Stage 3-4 并行执行图、计数验证、completed_with_errors 部分失败容忍

### 改进

- 方法论深化：两阶段角色模型、别名4类分类、一人一实体原则、13种剧情类型、金手指8类分类
- 情节点密度从 8-15 扩展为 3-40 动态范围（150-200字/个）
- 新增智能分块（>500章）、关系提取改为从情节点提取、框架识别自检模板
- story-setup agents_version 升级到 v4（7 个 story agent 参考提示词）
- story-import 管道表同步更新

### 修复

- material-decomposition.md 目录名统一为中文（chapters→章节 等）
- output-templates.md 情节点密度修复（8-15→3-40动态范围）、孤立阈值同步
- SKILL.md 链接引用修正、质量门控指向权威来源（material-decomposition.md）
- 孤立情节兜底 output-templates.md 同步为3层置信度
- 全书概要长度对标 zenstory（300-600→500-1000字），补全长篇体系感描述要求
- SKILL.md 管道表 Stage 3 孤立兜底步数修正（4→6）

## v0.6.0

### 新功能

- 新增 **story-explorer** 只读查询 Agent（Haiku）：10 种查询类型（角色状态、伏笔、设定、时间线、进度、上下文加载等），被 story-long-write、story-review、story 路由集成调用
- 新增 **story-import** 逆向导入 Skill：4 阶段流水线（确认来源 → 深度分析 → 结构迁移 → 项目激活），将已有小说反向解析为标准项目目录结构
- story 路由表新增「查故事资料」和「导入小说」入口

### 改进

- story-setup agents_version 升级到 v3（6 个 Agent）
- UPGRADING.md 新增 v3 版本记录
- story-long-write、story-review、workflow-daily 统一 story-explorer 集成模式（部署检测 + 结构化 prompt + 回退机制）
- structure-mapping.md 新增势力/散落情节/悬念映射规则

### 修复

- structure-mapping.md 细纲反推表格格式修复（2 列 → 3 列 Markdown 表格）
- story-explorer context_load 增加备用逻辑（追踪文件缺失时扫描正文推断章节号）
- 统一所有调用点的参数命名为中文（项目目录/查询类型/查询参数）

## v0.5.0

### 参考文件操作手册格式重构（核心变更）

- 全 skill references 从「知识百科」统一转为「操作手册」格式：决策路由表 + 指令语气 + 质量检查清单
- 大文件拆分：character-design → basics + methods + relations；genre-frameworks → catalog + mechanics + readers + formulas；hook-techniques → chapter + suspense + paragraph；outline-arrangement → methods + conflict + structure-theory + rhythm；style-modules → craft + genre-modules + combat-face + commercial-theory；advanced-plot-techniques → core-methods + frameworks + special-topics + emotion-system
- 新增 writing-craft.md（306行）、format-and-structure.md（137行）、emotional-methods.md（179行）
- 13 个共享文件跨 skill (long-write/short-write/short-analyze/deslop) byte-for-byte 同步
- Agent 模板和 SKILL.md 索引全部更新为新文件名

### 新功能

- 新增 story-researcher 资料研究 agent（CDP 搜索+正文提取+多源交叉验证）
- 长篇写作新增场景路由（开书/日更续写/大修）+ 日更工作流 + 大修工作流
- story skill 路由表新增「查资料」入口
- story-review 审查流程新增可选事实核查路径
- static-check.sh 新增 Check 6：检测反引号行内悬空文件引用
- static-check.sh Check 5 增强：支持 `(subagent_type: xxx)` 格式匹配

### 改进

- 精简 story-short-write SKILL.md 22.8KB→13.7KB，新建 writing-workflow.md
- 长篇写作增加创作公式引用、分层摘要协议与扫榜新元素提取
- reference 文件拆分压缩 + 术语直白化

### 修复

- opening-design.md 恢复 6 个丢失知识点（鬼灭之刃范例/信息团排版/改进方向/创意正确展开/期待感三路径/卖点设计与验证）
- 全文件箭头风格统一（`-->` → `->`，21 处）
- character-relations.md `x` → `×` 符号修正
- story-outline.md 裸路径 → 全路径修复
- SKILL.md Phase 3 索引补全 genre-writing-formulas.md
- 9 项 bug 修复与改进（B-1~B-5/D-1~D-3/D-4）
- 悬空文件引用修复（artifact-protocols/agent 模板/publishing-guide）

## v0.4.1

- 新增 story-review 多视角对抗式审查 skill
- 跨 skill 去 symlink 化 + CI 一致性校验
- AI 模式适配 + deslop 量化 + 拆文格式指引
- 指令冲突修复（细纲策略、节长标准、反转百分比）
- 起点扫榜失效链接修复（新书榜拆分 + 三江 URL 迁移）
- grep 全角冒号匹配修复
- 补齐 banned-words.md + CI 增加 references 内部交叉引用检查
- 消除跨 skill 引用残留 + 同步共享文件差异

## v0.4.0

- 新增 story-setup 基础设施部署 skill
- 添加 skill 结构静态检查脚本 + CI 集成
- browser-cdp 跨平台支持（Windows/macOS/Linux）
- 长篇拆文 skill 多项改进
- 短篇拆文/短篇写作 skill 迭代验证改进
- 拆文输出统一到拆文库/{书名}/

## v0.3.0

- 新增 story-cover 封面生成 skill
- 添加 ClawHub marketplace metadata
- 扫榜脚本体系升级（5 平台采集 + 共享模块 + 安全加固）
- 采集脚本数据正确性修复
- 7 个 skill 流程衔接表中文化
- 交叉引用一致性 + 术语通俗化 + 4 个新参考文件

## v0.2.0

- 知识库整合打磨（文件合并/去重/去教程化/SKILL.md 修复）
- 长篇小说目录结构升级（编排/追踪目录 + artifact 模板）
- 扫榜能力增强 + 新增七猫采集
- 新增 CONTRIBUTING.md

## v0.1.0

- 初始版本：长篇/短篇写作、拆文、扫榜、去 AI 味、浏览器操控
- 用 52000+ 本真实数据增强知识库
