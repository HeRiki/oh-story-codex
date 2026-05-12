---
name: browser-cdp
description: "通过 CDP 控制 Chrome 浏览器并复用已有登录态。覆盖：启动调试模式 Chrome、打开 URL、等待页面加载、执行 JavaScript、截图/快照、提取认证 token。触发方式：browser automation、CDP、agent-browser、浏览器操作、操作浏览器、Chrome CDP、复用登录态、extract token from browser。"
---

# Browser CDP 操作工具

通过 CDP 协议控制 Chrome，复用已有登录态，执行浏览器自动化操作。

## 前置条件

- Windows（实验性）/ macOS / Linux，已安装 Google Chrome
- Node.js 16+（Atomics.wait + SharedArrayBuffer）
- `agent-browser` 命令行工具已安装（`npm install -g agent-browser`）

---

## 第一步：启动 CDP Chrome 环境

从 `browser-cdp` skill 目录运行脚本；如果当前工作目录不是该 skill 目录，使用脚本的绝对路径。

```bash
node scripts/setup-cdp-chrome.js 9222
```

成功后所有 `agent-browser` 命令带 `--cdp 9222`。

---

## 常用操作

### 打开页面并等待加载

```bash
agent-browser --cdp 9222 open "<URL>"
agent-browser --cdp 9222 wait 3000
```

### 提取页面文本内容

```bash
agent-browser --cdp 9222 eval 'document.body.innerText.substring(0, 8000)'
```

### 提取 Auth Token

```bash
# 从 localStorage 或 cookie 提取
agent-browser --cdp 9222 eval 'localStorage.getItem("token") || document.cookie'
```

### 页面截图 / 交互式快照

```bash
# 查找页面元素（用于登录按钮等交互）
agent-browser --cdp 9222 snapshot -i
```

### 点击元素

```bash
agent-browser --cdp 9222 click "<CSS selector>"
```

### 填写表单

```bash
agent-browser --cdp 9222 type "<CSS selector>" "<text>"
```

---

## 常见问题

| 问题 | 解决方案 |
|------|----------|
| CDP 端口未监听 | 重新运行 `setup-cdp-chrome.js` |
| 页面跳转到登录页 | `snapshot -i` 找登录按钮并操作 |
| eval 返回 null | 检查 localStorage key 名称，或改用 `document.cookie` |
| Chrome 进程残留 | macOS/Linux: `pkill -9 -x 'Google Chrome'` / Windows: `taskkill /F /IM chrome.exe`，后重新运行脚本 |
