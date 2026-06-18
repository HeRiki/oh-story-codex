#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

const MAX_WALK_DEPTH = 6;
const MAX_SEARCH_DEPTH = 5;
const KNOWN_FORESHADOW_STATES = ["未埋", "已埋", "已回收", "已过期"];
const PROBLEM_FORESHADOW_STATES = ["已过期"];

function readInput() {
  try {
    const raw = fs.readFileSync(0, "utf8").trim();
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function isDirectory(target) {
  try {
    return fs.statSync(target).isDirectory();
  } catch {
    return false;
  }
}

function isFile(target) {
  try {
    return fs.statSync(target).isFile();
  } catch {
    return false;
  }
}

function findStoryRoot(startDir) {
  if (!startDir) return null;
  let dir = path.resolve(startDir || process.cwd());
  for (let i = 0; i <= MAX_WALK_DEPTH; i += 1) {
    if (isFile(path.join(dir, ".story-deployed"))) return dir;
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return null;
}

function inputCwd(input) {
  return input.cwd || input.working_directory || input.workingDirectory || "";
}

function walkFor(root, predicate, maxDepth = MAX_SEARCH_DEPTH) {
  const queue = [{ dir: root, depth: 0 }];
  const ignored = new Set([".git", "node_modules", ".venv", "venv", "__pycache__"]);

  while (queue.length) {
    const current = queue.shift();
    let entries = [];
    try {
      entries = fs.readdirSync(current.dir, { withFileTypes: true });
    } catch {
      continue;
    }

    for (const entry of entries) {
      const fullPath = path.join(current.dir, entry.name);
      if (predicate(fullPath, entry)) return fullPath;
      if (entry.isDirectory() && current.depth < maxDepth && !ignored.has(entry.name)) {
        queue.push({ dir: fullPath, depth: current.depth + 1 });
      }
    }
  }
  return null;
}

function findTrackingDir(root) {
  const direct = path.join(root, "追踪");
  if (isDirectory(direct)) return direct;
  const nested = walkFor(root, (fullPath, entry) => entry.isDirectory() && entry.name === "追踪");
  return nested || direct;
}

function findContextFile(root) {
  const direct = path.join(root, "追踪", "上下文.md");
  if (isFile(direct)) return direct;
  return walkFor(root, (fullPath, entry) => entry.isFile() && entry.name === "上下文.md");
}

function rel(root, target) {
  return target ? path.relative(root, target).replace(/\\/g, "/") || "." : "";
}

function runGit(root, args) {
  try {
    const result = spawnSync("git", args, {
      cwd: root,
      encoding: "utf8",
      timeout: 3000,
      stdio: ["ignore", "pipe", "ignore"],
    });
    return result.status === 0 ? (result.stdout || "").trim() : "";
  } catch {
    return "";
  }
}

function readHead(filePath, maxLines = 40) {
  if (!filePath || !isFile(filePath)) return "";
  try {
    return fs
      .readFileSync(filePath, "utf8")
      .split(/\r?\n/)
      .slice(0, maxLines)
      .join("\n")
      .trim();
  } catch {
    return "";
  }
}

function collectGapHints(root) {
  const hints = [];
  const settingDir = walkFor(root, (fullPath, entry) => entry.isDirectory() && entry.name === "设定", 3);
  const outlineDir = walkFor(root, (fullPath, entry) => entry.isDirectory() && entry.name === "大纲", 3);
  const proseDir = walkFor(root, (fullPath, entry) => entry.isDirectory() && entry.name === "正文", 3);
  const trackingDir = findTrackingDir(root);
  const contextFile = findContextFile(root);

  if (!settingDir) hints.push("未发现 `设定/` 目录");
  if (!outlineDir) hints.push("未发现 `大纲/` 目录");
  if (!proseDir) hints.push("未发现 `正文/` 目录");
  if (!isDirectory(trackingDir)) hints.push("未发现 `追踪/` 目录");
  if (!contextFile) hints.push("未发现 `追踪/上下文.md`");

  const foreshadowing = walkFor(root, (fullPath, entry) => entry.isFile() && entry.name === "伏笔.md");
  const timeline = walkFor(root, (fullPath, entry) => entry.isFile() && entry.name === "时间线.md");
  if (!foreshadowing) hints.push("未发现 `追踪/伏笔.md`");
  else {
    const problemCount = countProblemForeshadowing(foreshadowing);
    if (problemCount > 0) hints.push(`发现 ${problemCount} 条过期或异常伏笔，请检查 \`${rel(root, foreshadowing)}\``);
  }
  if (!timeline) hints.push("未发现 `追踪/时间线.md`");

  return hints;
}

function countProblemForeshadowing(filePath) {
  const text = readHead(filePath, 2000);
  if (!text) return 0;
  let statusIndex = -1;
  let count = 0;

  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed.startsWith("|") || !trimmed.endsWith("|")) continue;
    const cells = trimmed
      .split("|")
      .slice(1, -1)
      .map((cell) => cell.trim());
    if (!cells.length || cells.every((cell) => /^:?-{3,}:?$/.test(cell))) continue;

    if (statusIndex < 0) {
      const headerIndex = cells.findIndex((cell) => cell.includes("状态"));
      if (headerIndex >= 0) {
        statusIndex = headerIndex;
        continue;
      }
    }

    if (statusIndex < 0 || statusIndex >= cells.length) continue;
    const statusCell = cells[statusIndex];
    const known = KNOWN_FORESHADOW_STATES.find((state) => statusCell.includes(state));
    if (known) {
      if (PROBLEM_FORESHADOW_STATES.includes(known)) count += 1;
      continue;
    }
    if (statusCell) count += 1;
  }

  return count;
}

function outputAdditionalContext(hookEventName, message) {
  if (!message.trim()) return;
  console.log(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName,
        additionalContext: message,
      },
    }),
  );
}

function sessionContext(root, hookEventName) {
  const branch = runGit(root, ["rev-parse", "--abbrev-ref", "HEAD"]) || "unknown";
  const status = runGit(root, ["status", "--short"]);
  const contextFile = findContextFile(root);
  const contextPreview = readHead(contextFile, 36);
  const gaps = collectGapHints(root);

  const lines = [
    "## Oh Story Codex 项目上下文",
    `- 项目目录：${root}`,
    `- Git 分支：${branch}`,
    `- 工作区状态：${status ? "有未提交变更" : "干净或非 Git 仓库"}`,
  ];

  if (contextFile) {
    lines.push(`- 上下文文件：${rel(root, contextFile)}`);
  }

  if (gaps.length) {
    lines.push("", "### 自动缺口检查", ...gaps.map((item) => `- ${item}`));
  }

  if (contextPreview) {
    lines.push("", "### 上下文摘要", contextPreview);
  }

  if (hookEventName === "SessionStart") {
    lines.push("", "请在处理写作任务前优先参考以上上下文；若用户要求继续写作，先补齐必要上下文再动笔。");
  }

  return lines.join("\n");
}

function getPrompt(input) {
  return String(
    input.prompt ||
      input.user_prompt ||
      input.message ||
      input.transcript ||
      input.input ||
      "",
  );
}

function envFlag(name) {
  return /^(1|true|yes|on)$/i.test(String(process.env[name] || ""));
}

function handleSessionStart(input) {
  const root = findStoryRoot(inputCwd(input));
  if (!root) return;
  outputAdditionalContext("SessionStart", sessionContext(root, "SessionStart"));
}

function handleUserPromptSubmit(input) {
  const root = findStoryRoot(inputCwd(input));
  if (!root) return;
  const prompt = getPrompt(input);
  const looksStoryRelated = /写|小说|网文|章节|大纲|人设|设定|续写|审查|去AI|拆文|扫榜|封面/.test(prompt);
  if (!looksStoryRelated) return;
  outputAdditionalContext(
    "UserPromptSubmit",
    [
      "## Oh Story Codex 提示",
      "当前位于已初始化的网文项目中。处理本次写作请求前，先读取 `追踪/上下文.md` 和相关 `设定/`、`大纲/`、`追踪/` 文件；涉及续写时不要只依赖对话记忆。",
    ].join("\n"),
  );
}

function appendSessionLog(root) {
  if (!envFlag("STORY_SESSION_LOG")) return;
  const trackingDir = findTrackingDir(root);
  if (!isDirectory(trackingDir)) return;
  const logPath = path.join(trackingDir, "session-log.txt");
  const branch = runGit(root, ["rev-parse", "--abbrev-ref", "HEAD"]) || "unknown";
  const status = runGit(root, ["status", "--short"]);
  const line = [
    `[${new Date().toISOString()}]`,
    `branch=${branch}`,
    `dirty=${status ? "yes" : "no"}`,
  ].join(" ");
  fs.appendFileSync(logPath, `${line}\n`, "utf8");
}

function handleStop(input) {
  const root = findStoryRoot(inputCwd(input));
  if (!root) return;
  try {
    appendSessionLog(root);
  } catch {
    // Hooks must never block normal Codex flow.
  }
}

function getToolCommand(input) {
  const toolInput = input.tool_input || input.toolInput || {};
  return String(toolInput.command || input.command || "");
}

function getToolName(input) {
  return String(input.tool_name || input.toolName || input.name || input.tool || "");
}

function getToolInput(input) {
  return input.tool_input || input.toolInput || input.input || input.parameters || {};
}

function extractPatchTargetPaths(text) {
  const paths = [];
  for (const line of String(text || "").split(/\r?\n/)) {
    const match = line.match(/^\*\*\* (?:Add|Update) File: (.+)$/);
    if (match && match[1].trim()) paths.push(match[1].trim());
  }
  return paths;
}

function findTargetPaths(value, depth = 0) {
  if (!value || depth > 5) return [];
  if (typeof value === "string") return extractPatchTargetPaths(value);
  if (Array.isArray(value)) {
    const paths = [];
    for (const item of value) {
      paths.push(...findTargetPaths(item, depth + 1));
    }
    return paths;
  }
  if (typeof value !== "object") return [];
  const explicitPaths = [];
  for (const key of ["file_path", "filePath", "path", "target_path", "targetPath"]) {
    if (typeof value[key] === "string" && value[key]) explicitPaths.push(value[key]);
  }
  if (explicitPaths.length) return explicitPaths;

  const patchPaths = [];
  for (const key of ["patch", "diff"]) {
    if (typeof value[key] === "string") patchPaths.push(...extractPatchTargetPaths(value[key]));
  }
  if (patchPaths.length) return patchPaths;

  const nestedPaths = [];
  for (const key of ["tool_input", "toolInput", "input", "parameters", "args"]) {
    nestedPaths.push(...findTargetPaths(value[key], depth + 1));
  }
  return nestedPaths;
}

function insideRoot(root, target) {
  const relative = path.relative(root, target);
  return relative === "" || (!relative.startsWith("..") && !path.isAbsolute(relative));
}

function parseChapterNumber(fileName) {
  const match = String(fileName || "").match(/^第0*([0-9][0-9]*)章.*\.md$/);
  return match ? String(Number(match[1])) : "";
}

function hasMatchingOutline(outlineDir, chapterNumber) {
  if (!isDirectory(outlineDir) || !chapterNumber) return false;
  let entries = [];
  try {
    entries = fs.readdirSync(outlineDir, { withFileTypes: true });
  } catch {
    return false;
  }
  return entries.some((entry) => {
    if (!entry.isFile()) return false;
    const match = entry.name.match(/^细纲_第0*([0-9][0-9]*)章.*\.md$/);
    return match && String(Number(match[1])) === chapterNumber;
  });
}

function proseOutlineBlockReason(root, targetPath) {
  if (!targetPath) return "";
  const absolute = path.isAbsolute(targetPath) ? path.resolve(targetPath) : path.resolve(root, targetPath);
  if (!insideRoot(root, absolute)) return "";
  if (isFile(absolute)) return "";

  const base = path.basename(absolute);
  const parentName = path.basename(path.dirname(absolute));

  if (base === "正文.md") {
    const bookDir = path.dirname(absolute);
    const bookName = path.basename(bookDir);
    if (isDirectory(path.join(root, "拆文库", bookName))) return "";
    if (!isFile(path.join(bookDir, "设定.md"))) return "";
    if (isFile(path.join(bookDir, "小节大纲.md"))) return "";
    return [
      "⛔ 写正文被拦截：目标 `正文.md` 缺少同目录 `小节大纲.md`。",
      "先按 `story-short-write` 完成小节大纲，再创建正文；如果确需先起草，请先补建 `小节大纲.md`。",
    ].join("\n");
  }

  if (parentName !== "正文") return "";
  const chapterNumber = parseChapterNumber(base);
  if (!chapterNumber) return "";
  const bookDir = path.dirname(path.dirname(absolute));
  const bookName = path.basename(bookDir);
  if (isDirectory(path.join(root, "拆文库", bookName))) return "";
  const outlineDir = path.join(bookDir, "大纲");
  if (hasMatchingOutline(outlineDir, chapterNumber)) return "";
  return [
    `⛔ 写正文被拦截：第 ${chapterNumber} 章缺少细纲（大纲/细纲_第${chapterNumber}章.md）。`,
    "先按 `story-long-write` 单章流程补建细纲，再创建正文；如果确需先起草，请先补建对应细纲文件。",
  ].join("\n");
}

function maybeBlockProseWithoutOutline(input, root) {
  const toolName = getToolName(input);
  if (toolName && !/(Write|Edit|MultiEdit|apply_patch)$/i.test(toolName)) return false;
  const targetPaths = findTargetPaths(getToolInput(input));
  if (!targetPaths.length) targetPaths.push(...findTargetPaths(input));
  for (const targetPath of targetPaths) {
    const reason = proseOutlineBlockReason(root, targetPath);
    if (!reason) continue;
    outputAdditionalContext("PreToolUse", ["## Oh Story Codex 正文前置检查", reason].join("\n"));
    console.error(reason);
    process.exitCode = 2;
    return true;
  }
  return false;
}

function isGitCommitCommand(command) {
  const normalized = String(command || "").trim();
  if (!normalized) return false;
  if (/^(echo|printf|write-output|Write-Output)\b/.test(normalized)) return false;
  return /(^|[;&|]{1,2}\s*)(git|git\.exe)(\s+-[A-Za-z]\s+\S+|\s+--[A-Za-z0-9-]+(=\S+)?)*\s+commit\b/.test(normalized);
}

function toolSucceeded(input) {
  const output = input.tool_output || input.toolOutput || {};
  return output.exit_code === undefined || output.exit_code === 0;
}

function handlePostToolUse(input) {
  const root = findStoryRoot(inputCwd(input));
  if (!root) return;
  const command = getToolCommand(input);
  if (!toolSucceeded(input) || !isGitCommitCommand(command)) return;
  outputAdditionalContext(
    "PostToolUse",
    [
      "## Oh Story Codex 提交后提示",
      "刚刚执行了 `git commit`。如果本次提交涉及写作项目结构、角色设定、大纲、追踪文件或 hooks 行为，请确认 README、AGENTS.md 或 `追踪/上下文.md` 是否也需要同步更新。",
    ].join("\n"),
  );
}

function handlePreToolUse(input) {
  const root = findStoryRoot(inputCwd(input));
  if (!root) return;
  if (maybeBlockProseWithoutOutline(input, root)) return;
  const command = getToolCommand(input);
  if (!isGitCommitCommand(command)) return;
  outputAdditionalContext(
    "PreToolUse",
    [
      "## Oh Story Codex 提交前提醒",
      "本次即将执行 `git commit`。提交前请确认写作项目的设定、角色、大纲、追踪文件和文档是否已同步；如果只改正文，也要确认 `追踪/上下文.md` 是否需要更新当前位置和最近决策。",
    ].join("\n"),
  );
}

function main() {
  const mode = process.argv[2] || "";
  const input = readInput();
  const eventName = input.hook_event_name || input.hookEventName || mode;

  try {
    if (mode === "pre-tool-use" || eventName === "PreToolUse") handlePreToolUse(input);
    else if (mode === "session-start" || eventName === "SessionStart") handleSessionStart(input);
    else if (mode === "user-prompt-submit" || eventName === "UserPromptSubmit") handleUserPromptSubmit(input);
    else if (mode === "stop" || eventName === "Stop") handleStop(input);
    else if (mode === "post-tool-use" || eventName === "PostToolUse") handlePostToolUse(input);
  } catch (error) {
    if (process.env.OH_STORY_HOOK_DEBUG) {
      console.error(`oh-story hook error: ${String(error && error.message).slice(0, 200)}`);
    }
  }
}

main();
