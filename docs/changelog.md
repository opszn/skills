# Changelog

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
