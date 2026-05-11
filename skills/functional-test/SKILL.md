---
name: functional-test
description: "When the user asks for functional testing, feature testing, regression testing, test plan generation, or mentions '功能测试', '回归测试', '测试计划', '验收测试'. Generates test plans, executes tests, and produces reports for web, desktop, and CLI applications."
version: 1.0.0
license: MIT
author: opszn
user-invocable: true
tags: [testing, functional-test, regression, qa, test-plan]
compatibility: [claude-code]
---

# Functional Test

为任意应用生成测试计划、执行功能测试、产出测试报告。

## 触发条件

用户提到以下关键词时自动触发：functional test, feature test, regression test, test plan, 功能测试, 回归测试, 测试计划, 验收测试, 测试应用
用户手动调用：`/functional-test`

## 测试模式

| 模式 | 触发词 | 说明 |
|------|--------|------|
| `plan` | 生成测试计划、测试计划 | 分析应用结构，生成完整的测试矩阵 |
| `execute` | 执行测试、跑测试 | 按测试计划逐项执行 |
| `regression` | 回归测试、重新测试 | 重新运行历史测试，对比结果 |
| `report` | 测试报告、出报告 | 生成测试总结报告 |

默认流程：`plan` → `execute` → `report`

## 测试流程

### Phase 1: 应用分析

识别应用类型和可测试的功能点：

**Web 应用**：
```bash
# 识别页面结构和路由
grep -rn 'route\|path\|page\|view' --include='*.js' --include='*.ts' --include='*.jsx' --include='*.tsx' src/ 2>/dev/null | head -30
# 识别 API 端点
grep -rn 'fetch(\|axios\|api/\|/api/' --include='*.js' --include='*.ts' . 2>/dev/null | head -30
```

**Electron 桌面应用**：
```bash
# 识别 IPC handlers
grep -n 'ipcMain.handle\|ipcRenderer.invoke' --include='*.js' --include='*.ts' . 2>/dev/null
# 识别导航项
grep -n 'data-nav\|sidebar-item\|nav-' --include='*.html' . 2>/dev/null
# 识别设置项
grep -n 'settings-tab\|data-stab\|settings-pane' --include='*.html' . 2>/dev/null
```

**CLI 工具**：
```bash
# 识别子命令
grep -n 'command\|subcommand\|addCommand' --include='*.js' --include='*.ts' --include='*.py' . 2>/dev/null | head -20
# 识别参数
grep -n '\.option\|--\|argument' --include='*.js' --include='*.py' . 2>/dev/null | head -20
```

### Phase 2: 生成测试计划

根据应用类型加载对应的参考模板，生成测试矩阵。

**测试覆盖维度**：

1. **Golden Path** — 正常用户流程，预期无错误
2. **Edge Cases** — 边界条件：空数据、极大输入、特殊字符、网络断开、权限不足
3. **Regression** — 之前发现并已修复的 bug，确保不再出现
4. **UI/UX** — 响应式布局、暗色/亮色主题切换、加载状态、错误提示
5. **Performance Baseline** — 页面加载 < 2s、操作响应 < 500ms、列表渲染 > 1000 项不卡顿

**测试计划输出格式**：

```markdown
## 测试计划 — {应用名}

### 测试矩阵

| ID | 模块 | 测试项 | 类型 | 步骤 | 预期结果 | 优先级 |
|----|------|--------|------|------|----------|--------|
| T001 | 登录 | 正常登录 | Golden Path | 1. 输入正确用户名密码 2. 点击登录 | 跳转到首页 | P0 |
| T002 | 登录 | 错误密码 | Edge Case | 1. 输入正确用户名 2. 输入错误密码 | 显示错误提示 | P1 |

### 统计
- 总用例: X
- P0 (阻塞): X | P1 (重要): X | P2 (一般): X | P3 (次要): X
- Golden Path: X | Edge Cases: X | Regression: X | UI/UX: X | Performance: X
```

### Phase 3: 执行测试

逐项执行测试计划，记录结果：

```markdown
| ID | 状态 | 实际结果 | 备注 |
|----|------|----------|------|
| T001 | PASS | 跳转到首页 | - |
| T002 | FAIL | 无错误提示，直接报错 | 见 BUG-001 |
```

执行时：
- 使用浏览器工具（如有）验证页面状态
- 使用 CLI 命令验证后端行为
- 记录失败时的错误截图/日志
- 记录实际结果与预期结果的差异

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
| 数据 | 15 | 14 | 1 | 93.3% |

### 失败详情

| 用例 ID | 模块 | 测试项 | 预期 | 实际 | 严重度 |
|---------|------|--------|------|------|--------|
| T002 | 登录 | 错误密码 | 显示错误提示 | 无提示，直接 500 | HIGH |

### Bug 列表

| ID | 标题 | 严重度 | 关联用例 | 复现步骤 |
|----|------|--------|----------|----------|
| BUG-001 | 错误密码无提示 | HIGH | T002 | 1. 输入正确用户名 2. 输入错误密码 3. 点击登录 |
```

## 严重度定义

| 严重度 | 定义 | 示例 |
|--------|------|------|
| BLOCKER | 阻塞测试流程，无法继续 | 应用无法启动、页面白屏 |
| CRITICAL | 核心功能不可用 | 登录失败、数据丢失 |
| HIGH | 重要功能异常但可绕过 | 错误提示缺失、导出失败 |
| MEDIUM | 非核心功能异常 | 样式错乱、次要按钮无效 |
| LOW | 体验问题 | 拼写错误、对齐偏差 |

## 注意事项

- 测试计划生成后，应先让用户确认，再执行
- 执行测试时如遇到 BLOCKER 级问题，立即停止并报告
- 回归测试需要对比历史结果，标记新增的失败用例
- 对于无法自动执行的测试（如 UI 视觉检查），标记为 MANUAL 并提供检查要点
- 测试结果应保存到文件，方便后续回归对比
