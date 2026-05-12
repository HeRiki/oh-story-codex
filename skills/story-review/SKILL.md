---
name: story-review
description: |
  多视角对抗式审查。按故事架构、角色设计、文字质量、设定一致性四个视角找问题并综合裁决；用户明确要求多代理时可并行委派。
  触发方式：/story-review、/审查、「审查一下」「帮我审一下」
---

# story-review：多视角对抗式审查

你是审查协调器。按多个专业视角找问题，然后综合裁决。

**执行铁律：审查是找问题，不是验证正确性。**

---

## Review Mode 选择

- `/story-review` 或 `/story-review full` → 执行全部 4 个审查视角。只有用户明确要求多代理/并行委派时，才用 `spawn_agent` 分派这些视角；否则本线程依次完成。
- `/story-review lean` → 只执行 story-architect + consistency-checker 两个视角。
- `/story-review solo` → 只做基础检查。
- 未指定 → 默认 full，并告知用户执行模式。

---

## 审查流程（full 模式）

## Phase 1：收集待审查内容

1. 确定审查范围：
   - 用户指定了章节/文件 → 只审查指定内容
   - 用户未指定 → 审查最近修改的内容（git diff）或当前章节
2. 读取待审查的正文内容
3. 读取相关的设定文件和大纲
4. 识别目标平台（检查 `.active-book` 或用户指定），加载对应 rubric：
   - 番茄小说 → 读取 [references/rubrics/fanqie.md](references/rubrics/fanqie.md)
   - 起点 → 读取 [references/rubrics/qidian.md](references/rubrics/qidian.md)
   - 知乎盐言 → 读取 [references/rubrics/zhihu.md](references/rubrics/zhihu.md)
   - 未指定 → 默认加载 [references/quality-rubric.md](references/quality-rubric.md)

**Phase 1.5：可选 story-explorer 预查询**。如果项目已部署 story-explorer 参考提示词（检查 `.codex/story-agents/story-explorer.md` 是否存在），可读取该文件并用结构化查询预查设定摘要：`项目目录：{dir}\n查询类型：setting_appearances\n查询参数：{审查涉及的设定关键词}`。此步可选，跳过不影响审查流程。

## Phase 2：执行 4 个审查视角（+ 可选 researcher）

默认在本线程依次执行 4 个视角。若用户明确要求多代理/并行审查，可用 Codex `spawn_agent`，每个 agent 的 prompt 必须自包含文件路径和上下文，并说明对应审查视角。

**调用规则**：每个视角都必须基于同一份待审查内容、平台 rubric 和相关设定文件；如果使用 `spawn_agent`，不要依赖父对话隐含上下文。

**视角 1: story-architect**
- 审查视角：主题对齐、大纲结构、钩子/反转质量、范围控制
- 提示指令：
  ```
  你是 story-architect，从故事架构层面审查以下内容。
  你的任务是【找问题】，不是验证正确性。以最严苛的标准审视。
  审查范围：{待审查内容}
  平台评分标准：{Phase 1 加载的 rubric 内容}
  相关文件路径：{设定/大纲/细纲文件路径}
  检查项：
  1. 这一章是否推进了故事主题？
  2. 大纲结构是否完整（钩子/爽点/悬念）？
  3. 情绪节奏是否合理？
  4. 钩子和反转设计质量如何？
  5. 范围控制：有无角色/设定膨胀？
  6. 剧情循环是否存在且可重复？（参见 plot-core-methods "卡文对策与剧情循环设计"）
  7. 高潮场景是否用了蓄能→假胜→崩解结构？（参见 plot-core-methods "高潮构建公式"）
  8. 按平台 rubric 逐项对照，标记 PASS/FAIL

  输出格式：
  VERDICT: APPROVE / CONCERNS / REJECT
  FINDINGS: [结构/情节/节奏问题，附具体引用]
  RECOMMENDATIONS: [修改建议]
  ```

**视角 2: character-designer**
- 审查视角：角色语言风格一致性、对话质量、人物弧线
- 提示指令：
  ```
  你是 character-designer，从角色和对话层面审查以下内容。
  你的任务是【找问题】，不是验证正确性。以最严苛的标准审视。
  审查范围：{待审查内容}
  相关角色文件：{角色设定文件路径}
  检查项：
  1. 角色语言风格是否与语言风格档案一致？
  2. 对话是否千篇一律（AI味）？
  3. 人物弧线是否连贯？
  4. 角色行为是否符合其动机？
  5. 对话是否有潜台词和信息控制？
  6. 爱情线好感度与CP行为是否匹配？（参见 character-relations "好感度体系"）
  7. 好感度进度是否可感知？

  输出格式：
  VERDICT: APPROVE / CONCERNS / REJECT
  FINDINGS: [角色/对话问题，附具体引用]
  RECOMMENDATIONS: [修改建议]
  ```

**视角 3: narrative-writer**
- 审查视角：AI味检测、格式合规、节奏均匀度
- 提示指令：
  ```
  你是 narrative-writer，从文字质量层面审查以下内容。
  你的任务是【找问题】，不是验证正确性。以最严苛的标准审视。
  审查范围：{待审查内容}
  禁用词表：references/banned-words.md
  检查项：
  1. 是否存在禁用词/套话/陈词滥调？
  2. 格式是否合规（一段一句、≤60字、无空行、对话独立成行）？
  3. 节奏是否均匀（有无连续多节无情绪变化）？
  4. 身体部位同一词是否超 5 次？
  5. AI味分级（轻度/中度/重度）？

  输出格式：
  VERDICT: APPROVE / CONCERNS / REJECT
  FINDINGS: AI味级别: 轻度/中度/重度; [禁用词/格式/节奏问题，附具体引用]
  RECOMMENDATIONS: [修改建议]
  ```

**视角 4: consistency-checker**
- 审查视角：grep-first 事实冲突检测，输出 S1-S4 报告
- 提示指令：
  ```
  你是 consistency-checker，使用 grep-first 方式检测事实矛盾。
  你的任务是【找事实矛盾】，不做创作评判。
  审查范围：{待审查内容}
  已知角色：{从设定文件提取角色列表}
  项目路径：{工作目录路径，用于 grep 扫描}
  检查项：
  1. 角色属性是否前后一致？
  2. 世界规则是否被违反？
  3. 伏笔是否合理埋设/回收？
  4. 时间线是否自洽？
  5. 伏笔密度是否合理？

  输出格式：
  VERDICT: APPROVE / CONCERNS / REJECT
  FINDINGS: [S1/S2/S3/S4] 具体冲突描述（每条标注严重等级）
  RECOMMENDATIONS: [修复建议]
  ```

## Phase 3：综合裁决

1. 收集 4 个视角的 VERDICT 和 FINDINGS
2. 合并去重：将各视角的 FINDINGS 按严重程度排序（S1 > S2 > S3 > S4，AI味重度 > 中度 > 轻度）
3. **可选事实核查**：如果审查内容涉及需要验证的外部事实（历史年代、地理方位、职业细节等），读取 `.codex/story-agents/story-researcher.md` 作为研究角色说明；只有用户明确要求委派时才额外 `spawn_agent`
4. **分歧呈现**：如果审查视角间有冲突意见，明确呈现分歧让用户裁决
   - 例：story-architect 认为某段"结构合理"，但 character-designer 认为"角色弧线有问题"
   - 不要自动妥协，让用户看到双方理由
5. 输出综合审查报告

## Phase 4：输出报告（full 模式）

```
=== 故事审查报告 ===
Review Mode: full
审查范围: {章节/文件}

## Verdict Summary
- story-architect: APPROVE / CONCERNS(n) / REJECT
- character-designer: APPROVE / CONCERNS(n) / REJECT
- narrative-writer: APPROVE / CONCERNS(n) / REJECT
- consistency-checker: APPROVE / CONCERNS(n) / REJECT

## 综合评定
{APPROVE / CONCERNS / REJECT}

## 发现的问题
{按 S1→S4 分级列出所有问题}

## 视角分歧（如有）
{列出不同审查视角的意见}

## 修改建议
{按优先级排列}
```

---

## lean 模式

只执行 story-architect + consistency-checker，跳过 character-designer 和 narrative-writer。
其余流程同 full。

### lean 模式输出格式

```
=== 故事审查报告（lean）===
Review Mode: lean
审查范围: {章节/文件}

## Verdict Summary
- story-architect: APPROVE / CONCERNS(n) / REJECT
- consistency-checker: APPROVE / CONCERNS(n) / REJECT

## 综合评定
{APPROVE / CONCERNS / REJECT}

## 发现的问题
{按 S1→S4 分级}

## 修改建议
{按优先级排列}
```

## solo 模式

不做多视角拆分。skill 自身执行基础检查：
1. 格式合规性检查（一段一句、无空行、对话格式）
2. 简单的设定一致性 grep
3. 输出简化版报告

### solo 模式输出格式

```
=== 故事审查报告（solo）===
Review Mode: solo
审查范围: {章节/文件}

## 基础检查结果

### 格式合规性
- [ ] 段落 ≤60 字
- [ ] 无段间空行
- [ ] 对话独立成行
- 违规位置：{列出}

### 设定一致性（grep 扫描）
- {列出发现的矛盾}

### 简评
{一段话总结}
```

---

## 语言

- 所有输出使用中文
