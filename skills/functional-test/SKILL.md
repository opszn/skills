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

# Functional Test / 功能测试

Generate test plans, execute functional tests, and produce reports for any application. Supports persistent result storage and regression comparison.
为任意应用生成测试计划、执行功能测试、产出测试报告。支持持久化结果存储和回归对比。

## Trigger Conditions / 触发条件

Auto-trigger on: functional test, feature test, regression test, test plan, 功能测试, 回归测试, 测试计划, 验收测试, 测试应用
Manual: `/functional-test`

## Modes & Parameters / 测试模式与参数

### Modes

| Mode | Trigger | Description |
|------|---------|-------------|
| (default) | 功能测试, 测试应用 | Analyze app → generate plan → execute → report |
| `--plan` | 生成测试计划 | Analyze app structure, generate test matrix |
| `--execute` | 执行测试 | Execute tests from existing or newly generated plan |
| `--regression` | 回归测试 | Compare against last test run, mark changes |
| `--report` | 测试报告 | Generate test summary report only |

### Parameters

```
/functional-test --scope src/login     # Test only specified module/directory
/functional-test --priority P0         # Test only specified priority
/functional-test --module 登录,设置    # Test only specified feature modules
/functional-test --output report.md    # Save to custom path
/functional-test --type accessibility  # Specialized test type
```

**--type Specialized Tests**:

| Type | Checks |
|------|--------|
| `accessibility` | alt text, tab order, contrast, aria attributes, keyboard navigation |
| `api` | Status codes, timeouts, retry logic, request/response format |
| `performance` | Page load, API response, large data rendering |
| `visual` | Layout overflow, element overlap, text truncation, responsive |
| `security` | XSS injection, unencrypted transport, sensitive data exposure |

## Test Workflow / 测试流程

### Phase 0: Parameter Resolution

Parse mode and parameters to determine test scope, priority, output path, and specialized types.

### Phase 1: Deep App Analysis

Identify app type and testable features, output a "Testable Feature Checklist".

**Web Apps**:
```bash
# Routes/pages
grep -rn 'route\|path\|<Route\|createBrowserRouter\|react-router\|vue-router' --include='*.js' --include='*.ts' --include='*.tsx' --include='*.jsx' --include='*.vue' src/ 2>/dev/null | head -50
# Navigation
grep -rn 'nav-\|sidebar\|menu-item\|data-nav\|<Link ' --include='*.html' --include='*.tsx' --include='*.jsx' --include='*.vue' . 2>/dev/null | head -30
# Forms
grep -rn '<form\|<input\|<select\|<textarea\|onSubmit\|handleSubmit\|v-model' --include='*.html' --include='*.tsx' --include='*.jsx' --include='*.vue' . 2>/dev/null | head -50
# API calls
grep -rn 'fetch(\|axios\|\.get(\|\.post(\|/api/' --include='*.js' --include='*.ts' . 2>/dev/null | head -50
```

**Electron Desktop Apps**:
```bash
# IPC handlers
grep -rn 'ipcMain.handle\|ipcRenderer.invoke\|ipcRenderer.on' --include='*.js' --include='*.ts' . 2>/dev/null
# Navigation/UI
grep -rn 'data-nav\|sidebar-item\|tab-\|settings-pane\|settings-tab' --include='*.html' --include='*.js' . 2>/dev/null | head -30
# Settings
grep -rn 'settings\|preference\|config' --include='*.js' --include='*.ts' --include='*.json' . 2>/dev/null | grep -v node_modules | head -30
# Persistence
grep -rn 'localStorage\|sessionStorage\|fs\.write\|store\.set' --include='*.js' --include='*.ts' . 2>/dev/null | head -20
# Tray/window
grep -rn 'Tray\|BrowserWindow\|setBounds\|setTitle' --include='*.js' --include='*.ts' . 2>/dev/null | head -20
```

**CLI Tools**:
```bash
# Subcommands
grep -rn 'command\|subcommand\|addCommand\|program\.command' --include='*.js' --include='*.ts' --include='*.py' . 2>/dev/null | head -20
# Arguments
grep -rn '\.option\|--\|\.argument\|argparse' --include='*.js' --include='*.ts' --include='*.py' . 2>/dev/null | head -30
# Error handling
grep -rn 'process\.exit\|sys\.exit\|throw\|raise' --include='*.js' --include='*.ts' --include='*.py' . 2>/dev/null | head -20
```

Analysis results organized into: module list, testable interaction points per module (buttons, forms, API calls), data flow.

### Phase 2: Generate Test Plan

Generate test matrix from Phase 1's "Testable Feature Checklist".

**Coverage Dimensions**:

1. **Golden Path** — Normal user flow, at least 1 per interaction point
2. **Edge Cases** — Empty data, oversized input, special chars, network disconnect, insufficient permissions
3. **Regression** — Historical failure cases auto-included
4. **UI/UX** — Responsive, theme switching, loading states, error messages
5. **Performance Baseline** — Page load < 2s, response < 500ms, lists > 1000 items without lag
6. **Specialized** (when --type specified)

**Generation Rules**:
- Each identified module gets at least 2 test cases (1 Golden + 1 Edge Case)
- Login, payment, data-saving flows auto-labeled P0
- Secondary features P1, optimization suggestions P2
- Filter by `--scope` / `--module` / `--priority` if specified

**Test Plan Output**:
```markdown
## Test Plan — {app}

### App Profile
- Type: Web / Electron / CLI
- Identified modules: X (login, settings, data...)
- Identified interaction points: X (forms, buttons, APIs...)

### Test Matrix

| ID | Module | Test Item | Type | Steps | Expected | Priority |
|----|--------|-----------|------|-------|----------|----------|
| T001 | Login | Normal login | Golden Path | 1. Enter valid creds 2. Click login | Redirect to home | P0 |
| T002 | Login | Wrong password | Edge Case | 1. Valid user 2. Wrong password 3. Click login | Show error message | P1 |

### Statistics
- Total: X | P0 (blocker): X | P1 (important): X | P2 (normal): X
- Golden Path: X | Edge Cases: X | UI/UX: X | Performance: X
```

Show plan to user for confirmation before execution.

### Phase 3: Execute Tests

Execute test plan item by item, record results.

**Execution Methods**:
- Use Chrome DevTools MCP for page state and UI verification
- Use CLI commands for backend behavior and exit codes
- `mcp__chrome-devtools__take_snapshot` for UI state checks
- `mcp__chrome-devtools__click` / `mcp__chrome-devtools__fill` for interactions
- Record error screenshots, console logs, network requests on failure

**Result Recording**:
```markdown
| ID | Status | Actual Result | Notes |
|----|--------|--------------|-------|
| T001 | PASS | Redirected to home | - |
| T002 | FAIL | No error message, returns 500 | See BUG-001 |
```

Rules:
- BLOCKER issues: stop immediately and report
- MANUAL: mark un-automatable cases (e.g., visual checks), provide checkpoints
- Record difference between actual and expected results

### Phase 3.5: Persist Test Results

Write full results to `.claude/test-results/`:

```bash
RESULTS_DIR=".claude/test-results"
mkdir -p "$RESULTS_DIR"
RUN_ID=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/test-run-$RUN_ID.json"
```

JSON format:
```json
{
  "runId": "20260511-230000",
  "date": "2026-05-11",
  "appType": "electron",
  "totalCases": 50,
  "passed": 42, "failed": 5, "skipped": 2, "blocked": 1,
  "passRate": "84%",
  "cases": [
    {"id": "T001", "module": "Login", "name": "Normal login", "type": "Golden Path", "priority": "P0", "status": "PASS", "actual": "Redirected to home"}
  ],
  "bugs": [
    {"id": "BUG-001", "title": "No error on wrong password", "severity": "HIGH", "caseId": "T002"}
  ]
}
```

Update `$RESULTS_DIR/test-latest.json` as latest copy. If `--output <path>` used, also save to custom path.

### Phase 4: Generate Report

```markdown
## Test Report — {app} — {date}

### Overview

| Total | Passed | Failed | Skipped | Blocked | Pass Rate |
|-------|--------|--------|---------|---------|-----------|
| 50 | 42 | 5 | 2 | 1 | 84% |

### By Module

| Module | Total | Passed | Failed | Pass Rate |
|--------|-------|--------|--------|-----------|
| Login | 8 | 7 | 1 | 87.5% |

### Failure Details

| Case ID | Module | Test Item | Expected | Actual | Severity |
|---------|--------|-----------|----------|--------|----------|
| T002 | Login | Wrong password | Show error | No message, 500 error | HIGH |

### Bug List

| ID | Title | Severity | Cases | Reproduction Steps |
|----|-------|----------|-------|--------------------|
| BUG-001 | No error on wrong password | HIGH | T002 | 1. Valid user 2. Wrong password 3. Click login |
```

### Phase 4.5: Regression Comparison (--regression)

After Phase 4, when `--regression` is used:

1. Read `.claude/test-results/test-latest.json` as baseline
2. Compare current vs last results, mark changes:
   - `FIXED` — failed last time, passed now
   - `REGRESSED` — passed last time, failed now
   - `STILL_FAIL` — continuously failing
   - `NEW` — newly added test case

Output:
```markdown
### Regression Comparison

| Metric | Last Run | This Run | Change |
|--------|----------|----------|--------|
| Total | 50 | 53 | +3 |
| Pass Rate | 84% | 91% | +7% |
| Fixed | - | 4 | |
| New Failures | - | 1 | |

### Changes

| Case ID | Last Status | This Status | Change | Details |
|---------|-------------|-------------|--------|---------|
| T015 | FAIL | PASS | FIXED | BUG-003 resolved |
| T023 | PASS | FAIL | REGRESSED | Blank screen after login |
```

## Severity Definitions / 严重度定义

| Severity | Definition | Example |
|----------|-----------|---------|
| BLOCKER | Blocks test flow, cannot continue | App won't start, blank page, login completely broken |
| CRITICAL | Core feature completely broken | Data loss, payment failure, save failure |
| HIGH | Important feature broken but workaround exists | Missing error messages, export broken, search useless |
| MEDIUM | Non-core feature anomaly | Style broken, secondary button dead, wrong text |
| LOW | UX issue | Alignment off, missing loading animation, inconsistent spacing |

## Notes / 注意事项

- Show test plan to user for confirmation before executing
- Stop and report immediately on BLOCKER issues
- Regression test reads `test-latest.json` as baseline
- Non-automatable tests marked MANUAL with checkpoints
- All results saved to `.claude/test-results/` for future regression comparison
- `--scope` / `--module` / `--priority` can be combined to narrow scope
- Specialized test (--type) failures count toward total pass rate
