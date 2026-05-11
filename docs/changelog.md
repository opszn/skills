# Changelog

## [1.1.0] — 2026-05-11

### `/code-audit` 新增三大能力

- **持久化报告输出**
  - 审计结果自动保存到 `.claude/audit-reports/audit-report-{date}.md`
  - 维护 `audit-latest.md` 指向最新报告
  - 支持 `--output <path>` 保存到指定路径

- **修复验证（`--verify`）**
  - 读取上次审计报告，针对每条发现重新执行对应的 grep 检查
  - 支持 `--verify --finding <N>` 验证单条发现
  - 输出 FIXED / FAILING / MODIFIED 状态

- **SAST 自动执行**
  - 自动检测并运行 npm audit / semgrep / pip-audit / govulncheck / cargo audit
  - 解析结构化结果（JSON），并入审计报告
  - 支持 `--sast` 模式仅执行依赖扫描
  - 新增辅助脚本：`scripts/run-sast.sh`、`scripts/verify-finding.sh`

- **新增作用域参数**：`--output`、`--verify`、`--sast`

## [1.0.0] — 2026-05-11

### 首次发布

- `/code-audit` — 四模式代码审计（quick/full/security/quality）
  - 支持多语言项目（JS/TS/Python/Go/Rust 等）
  - 安全检查清单覆盖 OWASP Top 10
  - 质量检查清单覆盖死代码/重复/复杂度/错误处理
  - 严重度分级输出 + 修复建议

- `/functional-test` — 功能测试计划生成与执行
  - 支持 Web 应用、Electron 桌面应用、CLI 工具
  - 测试覆盖：Golden path / Edge cases / Regression / UI-UX / Performance
  - 测试报告：通过率统计 + 失败详情 + Bug 列表
