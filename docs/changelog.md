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

## [2.0.0] — 2026-05-11

### `/functional-test` 全面升级

- **深度应用分析**
  - Web：路由/导航/表单/API 调用结构化识别
  - Electron：IPC handlers/托盘/设置/数据持久化识别
  - CLI：子命令/参数定义/错误处理/管道识别
  - 输出"可测试功能清单"，不再死套模板

- **持久化测试结果**
  - JSON 格式保存到 `.claude/test-results/test-run-{date}.json`
  - 维护 `test-latest.json` 指向最新结果

- **回归对比（`--regression`）**
  - 读取 `test-latest.json` 作为基线
  - 对比标注：FIXED / REGRESSED / STILL_FAIL / NEW
  - 输出通过率变化趋势

- **参数化控制**
  - `--scope` 指定模块范围
  - `--priority` 按优先级筛选
  - `--module` 按功能模块筛选
  - `--output` 自定义输出路径
  - `--type` 专项测试（accessibility/api/performance/visual/security）

- **专项测试类型**
  - accessibility：alt 文本、tab 顺序、aria 属性
  - api：状态码、超时、重试
  - performance：加载时间、响应时间、大数据渲染
  - visual：布局溢出、元素重叠
  - security：XSS、未加密传输、敏感信息暴露

- **新增辅助脚本**：`scripts/compare-results.sh`
- **新增参考文档**：`references/testing-patterns.md`

## [2.0.0] — 2026-05-11 (writing)

### `/深度写作` 全新发布

- **解耦内部依赖**
  - 默认输出 markdown 文件到 `writing-drafts/`
  - 语雀发布作为可选插件（`--publish yuque`）
  - 支持 clipboard 输出

- **AI 去痕审查**
  - 扫描 50+ 中文 AI 写作指纹模式（8 大类别）
  - 逐项标记并建议替换，不机械替换
  - 新增参考文档：`references/ai-patterns-zh.md`

- **文风档案学习**
  - 从 2-3 篇用户文章中提取文风特征
  - 保存到 `.claude/writing-voice.json`
  - 后续写作匹配用户真实文风

- **三轮修订流程**
  - 4a 起草：案例驱动，保存到草稿目录
  - 4b 审查：分级审查（Critical/Significant/Minor）
  - 4c 润色：标题、开头钩子、金句、节奏检查

- **新增辅助脚本**：`scripts/write-draft.sh`（草稿版本管理）

- **新增参数**：`--output`、`--publish`、`--voice`、`--no-review`
