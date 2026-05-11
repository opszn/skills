---
name: functional-test
description: "When the user asks for functional testing, feature testing, regression testing, test plan generation, or mentions '功能测试', '回归测试', '测试计划', '验收测试'. Generates test plans, executes tests, produces reports, with persistent result storage and regression comparison."
version: 2.0.0
license: MIT
author: opszn
user-invocable: true
tags: [testing, functional-test, regression, qa, test-plan, accessibility, api-testing]
compatibility: [claude-code]
---

# Functional Test

为任意应用生成测试计划、执行功能测试、产出测试报告。支持持久化结果存储和回归对比。

## 触发条件

用户提到以下关键词时自动触发：functional test, feature test, regression test, test plan, 功能测试, 回归测试, 测试计划, 验收测试, 测试应用
用户手动调用：`/functional-test`

## 测试模式与参数

### 模式

| 模式 | 触发词 | 说明 |
|------|--------|------|
| (默认) | 功能测试、测试应用 | 分析应用 → 生成计划 → 执行 → 报告 |
| `--plan` | 生成测试计划 | 分析应用结构，生成测试矩阵 |
| `--execute` | 执行测试 | 按现有计划或新生成计划执行 |
| `--regression` | 回归测试 | 对比上次测试结果，标注变化 |
| `--report` | 测试报告 | 生成测试总结报告 |

### 参数

```
/functional-test --scope src/login     # 只测试指定模块/目录
/functional-test --priority P0         # 只测试指定优先级
/functional-test --module 登录,设置    # 只测试指定功能模块
/functional-test --output report.md    # 保存到指定路径
/functional-test --type accessibility  # 专项测试类型
```

**--type 专项测试**：

| 类型 | 检查内容 |
|------|----------|
| `accessibility` | alt 文本、tab 顺序、对比度、aria 属性、键盘导航 |
| `api` | API 状态码、超时、重试、请求/响应格式 |
| `performance` | 页面加载、API 响应、大数据渲染 |
| `visual` | 布局溢出、元素重叠、文字截断、响应式 |
| `security` | XSS 注入、未加密传输、敏感信息暴露 |

## 测试流程

### Phase 0: 参数解析

解析用户传入的模式和参数，确定测试范围、优先级、输出路径、专项类型。

### Phase 1: 深度应用分析

识别应用类型和可测试功能点，输出"可测试功能清单"。

**Web 应用**：
```bash
# 路由/页面结构
grep -rn 'route\|path\|<Route\|createBrowserRouter\|react-router\|vue-router' --include='*.js' --include='*.ts' --include='*.tsx' --include='*.jsx' --include='*.vue' src/ 2>/dev/null | head -50
# 导航元素
grep -rn 'nav-\|sidebar\|menu-item\|data-nav\|<Link ' --include='*.html' --include='*.tsx' --include='*.jsx' --include='*.vue' . 2>/dev/null | head -30
# 表单元素
grep -rn '<form\|<input\|<select\|<textarea\|onSubmit\|handleSubmit\|v-model' --include='*.html' --include='*.tsx' --include='*.jsx' --include='*.vue' . 2>/dev/null | head -50
# API 调用
grep -rn 'fetch(\|axios\|\.get(\|\.post(\|/api/' --include='*.js' --include='*.ts' . 2>/dev/null | head -50
```

**Electron 桌面应用**：
```bash
# IPC handlers
grep -rn 'ipcMain.handle\|ipcRenderer.invoke\|ipcRenderer.on' --include='*.js' --include='*.ts' . 2>/dev/null
# 导航/UI 结构
grep -rn 'data-nav\|sidebar-item\|tab-\|settings-pane\|settings-tab' --include='*.html' --include='*.js' . 2>/dev/null | head -30
# 设置项
grep -rn 'settings\|preference\|config' --include='*.js' --include='*.ts' --include='*.json' . 2>/dev/null | grep -v node_modules | head -30
# 数据持久化
grep -rn 'localStorage\|sessionStorage\|fs\.write\|store\.set' --include='*.js' --include='*.ts' . 2>/dev/null | head -20
# 托盘/窗口
grep -rn 'Tray\|BrowserWindow\|setBounds\|setTitle' --include='*.js' --include='*.ts' . 2>/dev/null | head -20
```

**CLI 工具**：
```bash
# 子命令
grep -rn 'command\|subcommand\|addCommand\|program\.command' --include='*.js' --include='*.ts' --include='*.py' . 2>/dev/null | head -20
# 参数定义
grep -rn '\.option\|--\|\.argument\|argparse' --include='*.js' --include='*.ts' --include='*.py' . 2>/dev/null | head -30
# 错误处理
grep -rn 'process\.exit\|sys\.exit\|throw\|raise' --include='*.js' --include='*.ts' --include='*.py' . 2>/dev/null | head -20
```

分析结果整理为：模块列表、每个模块的可测试交互点（按钮、表单、API 调用等）、数据流。

### Phase 2: 生成测试计划

基于 Phase 1 的"可测试功能清单"生成测试矩阵。

**测试覆盖维度**：

1. **Golden Path** — 正常用户流程，每个交互点至少 1 条
2. **Edge Cases** — 空数据、超长输入、特殊字符、网络断开、权限不足
3. **Regression** — 历史失败用例自动纳入
4. **UI/UX** — 响应式、主题切换、加载状态、错误提示
5. **Performance Baseline** — 页面加载 < 2s、操作响应 < 500ms、列表 > 1000 项不卡顿
6. **专项测试**（--type 指定时）

**生成规则**：

- 每个识别出的功能模块至少 2 条用例（1 Golden + 1 Edge Case）
- 登录、支付、数据保存等核心流程自动标 P0
- 次要功能标 P1，优化建议标 P2
- 如用户指定 `--scope` / `--module` / `--priority`，按条件过滤

**测试计划输出格式**：

```markdown
## 测试计划 — {应用名}

### 应用画像
- 类型: Web / Electron / CLI
- 识别模块: X 个（登录、设置、数据...）
- 识别交互点: X 个（表单、按钮、API...）

### 测试矩阵

| ID | 模块 | 测试项 | 类型 | 步骤 | 预期结果 | 优先级 |
|----|------|--------|------|------|----------|--------|
| T001 | 登录 | 正常登录 | Golden Path | 1. 输入正确用户名密码 2. 点击登录 | 跳转到首页 | P0 |
| T002 | 登录 | 错误密码 | Edge Case | 1. 输入正确用户名 2. 输入错误密码 3. 点击登录 | 显示错误提示 | P1 |

### 统计
- 总用例: X
- P0 (阻塞): X | P1 (重要): X | P2 (一般): X
- Golden Path: X | Edge Cases: X | UI/UX: X | Performance: X
```

生成计划后展示给用户确认，确认后再执行。

### Phase 3: 执行测试

逐项执行测试计划，记录结果。

**执行方式**：

- 使用浏览器工具（Chrome DevTools MCP）验证页面状态和交互
- 使用 CLI 命令验证后端行为和退出码
- 使用 `mcp__chrome-devtools__take_snapshot` 检查 UI 状态
- 使用 `mcp__chrome-devtools__click` / `mcp__chrome-devtools__fill` 执行操作
- 记录失败时的错误截图、控制台日志、网络请求

**结果记录**：

```markdown
| ID | 状态 | 实际结果 | 备注 |
|----|------|----------|------|
| T001 | PASS | 跳转到首页 | - |
| T002 | FAIL | 无错误提示，直接报错 500 | 见 BUG-001 |
```

执行规则：
- BLOCKER 级问题立即停止并报告
- MANUAL 标记无法自动验证的用例（如视觉检查），提供检查要点
- 记录实际结果与预期结果的差异

### Phase 3.5: 持久化测试结果

将完整测试结果写入 `.claude/test-results/`：

```bash
RESULTS_DIR=".claude/test-results"
mkdir -p "$RESULTS_DIR"
RUN_ID=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/test-run-$RUN_ID.json"
```

JSON 格式：
```json
{
  "runId": "20260511-230000",
  "date": "2026-05-11",
  "appType": "electron",
  "totalCases": 50,
  "passed": 42, "failed": 5, "skipped": 2, "blocked": 1,
  "passRate": "84%",
  "cases": [
    {"id": "T001", "module": "登录", "name": "正常登录", "type": "Golden Path", "priority": "P0", "status": "PASS", "actual": "跳转到首页"}
  ],
  "bugs": [
    {"id": "BUG-001", "title": "错误密码无提示", "severity": "HIGH", "caseId": "T002"}
  ]
}
```

同时更新 `$RESULTS_DIR/test-latest.json` 为最新结果副本。如用户指定 `--output <path>`，额外保存到指定路径。

### Phase 4: 生成报告

```markdown
## 测试报告 — {应用名} — {日期}

### 总览

| 总用例 | 通过 | 失败 | 跳过 | 阻塞 | 通过率 |
|--------|------|------|------|------|--------|
| 50 | 42 | 5 | 2 | 1 | 84% |

### 按模块分布

| 模块 | 总数 | 通过 | 失败 | 通过率 |
|------|------|------|------|--------|
| 登录 | 8 | 7 | 1 | 87.5% |

### 失败详情

| 用例 ID | 模块 | 测试项 | 预期 | 实际 | 严重度 |
|---------|------|--------|------|------|--------|
| T002 | 登录 | 错误密码 | 显示错误提示 | 无提示，直接 500 | HIGH |

### Bug 列表

| ID | 标题 | 严重度 | 关联用例 | 复现步骤 |
|----|------|--------|----------|----------|
| BUG-001 | 错误密码无提示 | HIGH | T002 | 1. 输入正确用户名 2. 输入错误密码 3. 点击登录 |
```

### Phase 4.5: 回归对比（--regression 模式）

当用户使用 `--regression` 时，在 Phase 4 之后追加：

1. 读取 `.claude/test-results/test-latest.json` 作为基线
2. 对比本次与上次结果，标记变化：
   - `FIXED` — 上次失败，本次通过
   - `REGRESSED` — 上次通过，本次失败
   - `STILL_FAIL` — 持续失败
   - `NEW` — 新增测试用例

输出格式：

```markdown
### 回归对比

| 指标 | 上次 | 本次 | 变化 |
|------|------|------|------|
| 总用例 | 50 | 53 | +3 |
| 通过率 | 84% | 91% | +7% |
| 已修复 | - | 4 | |
| 新失败 | - | 1 | |

### 变化详情

| 用例 ID | 上次状态 | 本次状态 | 变化 | 详情 |
|---------|----------|----------|------|------|
| T015 | FAIL | PASS | FIXED | BUG-003 已解决 |
| T023 | PASS | FAIL | REGRESSED | 登录后页面白屏 |
```

## 严重度定义

| 严重度 | 定义 | 示例 |
|--------|------|------|
| BLOCKER | 阻塞测试流程，无法继续 | 应用无法启动、页面白屏、登录完全不可用 |
| CRITICAL | 核心功能完全不可用 | 数据丢失、支付失败、保存失败 |
| HIGH | 重要功能异常但可绕过 | 错误提示缺失、导出失败、搜索无效 |
| MEDIUM | 非核心功能异常 | 样式错乱、次要按钮无效、文案错误 |
| LOW | 体验问题 | 对齐偏差、加载动画缺失、间距不一致 |

## 注意事项

- 测试计划生成后，应先展示给用户确认，再执行
- 执行测试时如遇到 BLOCKER 级问题，立即停止并报告
- 回归测试读取 `test-latest.json` 作为基线，对比标注变化
- 无法自动执行的测试标记为 MANUAL，提供检查要点
- 所有测试结果保存到 `.claude/test-results/`，方便后续回归对比
- `--scope` / `--module` / `--priority` 参数可组合使用，缩小测试范围
- 专项测试（--type）的失败项计入总通过率
