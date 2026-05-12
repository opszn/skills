# AI Dev Skills

Claude Code skills plugin — **code audit** + **functional testing**, for web, desktop and CLI applications in any programming language.

[中文文档](#中文文档)

## Installation

### Method 1: From GitHub (Recommended)

```bash
/plugin install github:opszn/skills
```

### Method 2: Local Install

```bash
git clone https://github.com/opszn/skills.git
cd skills
/plugin install ./
```

### Method 3: Manual

Copy the `skills/` directory to your project's `.claude/skills/` directory:

```bash
cp -r skills/code-audit ~/.claude/skills/
cp -r skills/functional-test ~/.claude/skills/
```

## Skills

### `/code-audit` — Code Audit

Systematic code audit for any project, covering security, architecture, quality, and performance.

**Four audit modes:**

| Mode | Use Case | Time |
|------|----------|------|
| `quick` | Fast scan for obvious issues | < 2 min |
| `full` | Full depth audit (default) | 5-15 min |
| `security` | OWASP Top 10 focused | 5-10 min |
| `quality` | Code quality / smells | 3-8 min |

**Scope control:**

| Flag | Description |
|------|-------------|
| (none) | Smart scan: Top 20 largest files + entry points |
| `--scope src/` | Audit specific directory |
| `--scope main.js` | Audit specific file |
| `--diff` | Audit last 5 commits only |
| `--full` | Full scan of all source files |
| `--sarif` | Also output SARIF 2.1 JSON |
| `--output report.md` | Save report to custom path |
| `--verify` | Verify fixes from last audit |
| `--verify --finding 1` | Verify a specific finding |
| `--sast` | SAST-only scan (dependencies) |

**Examples:**

```bash
/code-audit                    # Full audit (smart scan)
/code-audit --quick            # Quick scan
/code-audit --security         # Security-focused audit
/code-audit --scope src/api/   # Audit only API directory
/code-audit --diff             # Audit recent changes
/code-audit --verify           # Verify last audit's findings
/code-audit --sast             # Dependency vulnerability scan only
```

**Output:** Severity-graded findings with confidence scores, CWE IDs, exploit scenarios, fix effort estimates, and actionable remediation roadmap. Reports are automatically saved to `.claude/audit-reports/`.

### `/functional-test` — Functional Testing

Generate test plans, execute tests, and produce test reports.

**Work modes:**

| Mode | Description |
|------|-------------|
| (default) | Analyze app → generate plan → execute → report |
| `--plan` | Analyze app structure, generate test matrix |
| `--execute` | Execute tests from plan |
| `--regression` | Re-run historical tests, compare results |
| `--report` | Generate test summary report |

**Parameters:**

| Flag | Description |
|------|-------------|
| `--scope src/login` | Test only specified module/directory |
| `--priority P0` | Test only specified priority |
| `--module 登录,设置` | Test only specified feature modules |
| `--output report.md` | Save report to custom path |
| `--type accessibility` | Specialized test type (accessibility/api/performance/visual/security) |

**Examples:**

```bash
/functional-test                    # Full test cycle
/functional-test --plan             # Generate plan only
/functional-test --scope settings   # Test only settings module
/functional-test --regression       # Regression test with comparison
/functional-test --type api         # API-focused testing
```

**Coverage:** Golden Path / Edge Cases / Regression / UI-UX / Performance Baseline / Specialized Tests

**New capabilities (v2.0.0):**

| Capability | Description |
|------------|-------------|
| Deep app analysis | Structured analysis of routes/forms/APIs/IPC before test generation |
| Persistent results | Test results saved to `.claude/test-results/` as JSON |
| Regression comparison | `--regression` compares against baseline, marks fixed/new failures |
| Specialized tests | `--type accessibility/api/performance/visual/security` |

### `/deep-writing` — Deep Writing

Write publishable deep-thinking articles from real experiences and observations.

**Workflow:**

```
Trigger event → Research (Agent) → Structure → Draft → Review → Polish → Output
```

**Three-phase revision:**

| Phase | Description |
|-------|-------------|
| 4a: Draft | Case-driven writing, saved to `writing-drafts/` |
| 4b: Review | Graded review (Critical/Significant/Minor) + AI fingerprint scan |
| 4c: Polish | Title, opening hooks, golden quote, rhythm check |

**Parameters:**

| Flag | Description |
|------|-------------|
| `--output markdown` | Save as .md file (default) |
| `--output clipboard` | Copy to clipboard |
| `--output yuque` | Publish to Yuque (requires Yuque MCP) |
| `--publish yuque` | Explicitly publish to Yuque |
| `--voice sample.md` | Provide writing samples for voice learning |
| `--no-review` | Skip review, output draft directly |

**AI dehumanization:** Scans 50+ Chinese AI writing fingerprint patterns across 8 categories (excessive emphasis, empty引导, mechanical parallelism, modifier stacking, vague conclusions, hedging, template openings, transition cliches) and suggests replacements.

**Voice profile:** Learns from 2-3 user writing samples, extracts sentence length, paragraph structure, tone, avoided words, preferred transitions. Saved to `.claude/writing-voice.json`.

**Examples:**

```bash
/深度写作 AI依赖悖论
/深度写作 话题=Vibe Coding的风险 风格=行业观察
/深度写作 自动化运维的陷阱 --output clipboard
/深度写作 话题=AI工具选择 风格=技术反思 --publish yuque
```

## Project Structure

```
ai-dev-skills/
├── .claude-plugin/
│   ├── plugin.json           # Plugin metadata
│   └── marketplace.json      # Marketplace registration
├── README.md                 # This file
├── LICENSE                   # MIT
├── CONTRIBUTING.md           # Contribution guidelines
├── skills/
│   ├── code-audit/
│   │   ├── SKILL.md          # Code audit skill
│   │   ├── scripts/          # Helper scripts
│   │   │   ├── run-sast.sh       # SAST auto-execution
│   │   │   └── verify-finding.sh # Fix verification
│   │   └── references/       # Checklists
│   │       ├── security-checklist.md   # OWASP Top 10
│   │       └── quality-checklist.md    # Code quality
│   ├── functional-test/
│   │   ├── SKILL.md          # Functional test skill
│   │   ├── scripts/          # Helper scripts
│   │   │   └── compare-results.sh # Regression comparison
│   │   └── references/       # Templates and patterns
│   │       ├── test-plan-template.md   # Test plan templates
│   │       ├── bug-report-template.md  # Bug report template
│   │       └── testing-patterns.md     # Testing patterns per app type
│   └── writing/
│       └── deep-writing/
│           ├── SKILL.md          # Deep writing skill
│           ├── scripts/          # Helper scripts
│           │   └── write-draft.sh    # Draft version management
│           └── references/       # Reference materials
│               └── ai-patterns-zh.md # Chinese AI writing fingerprints
└── docs/
    └── changelog.md          # Version history
```

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### Adding a New Skill
1. Create a directory under `skills/`
2. Create `SKILL.md` with YAML frontmatter
3. Add reference docs under `references/`
4. Update `.claude-plugin/marketplace.json`

### Improving Existing Skills
1. Keep SKILL.md under 500 lines
2. Move detailed content to `references/`
3. Update `docs/changelog.md`

## License

[MIT](LICENSE)

---

## 中文文档

### 安装

```bash
/plugin install github:opszn/skills
```

### `/code-audit` — 代码审计

对任意项目进行系统性代码审计，覆盖安全、架构、质量、性能四个维度。

**四种审计模式：**

| 模式 | 适用场景 | 耗时 |
|------|----------|------|
| `quick` | 快速扫描明显问题 | < 2 分钟 |
| `full` | 全面深度审计（默认） | 5-15 分钟 |
| `security` | OWASP Top 10 安全专项 | 5-10 分钟 |
| `quality` | 代码质量专项 | 3-8 分钟 |

**新增能力（v1.1.0）：**

| 能力 | 说明 |
|------|------|
| 持久化报告 | 审计结果自动保存到 `.claude/audit-reports/` |
| 修复验证 | `/code-audit --verify` 验证问题是否已修复 |
| SAST 自动执行 | 自动检测并运行 npm audit / semgrep / pip-audit / govulncheck |

### `/functional-test` — 功能测试

生成测试计划、执行功能测试、产出测试报告。

**新增能力（v2.0.0）：**

| 能力 | 说明 |
|------|------|
| 深度应用分析 | 测试前结构化分析路由/表单/API/IPC，生成可测试功能清单 |
| 持久化测试结果 | 结果以 JSON 格式保存到 `.claude/test-results/` |
| 回归对比 | `--regression` 对比基线，标注已修复/新失败/持续失败 |
| 参数化控制 | `--scope` / `--priority` / `--module` / `--type` 灵活筛选 |
| 专项测试 | `--type accessibility/api/performance/visual/security` |

**覆盖维度：** Golden Path / Edge Cases / Regression / UI-UX / Performance Baseline / 专项测试

### `/deep-writing` — 深度写作

从真实经历出发，撰写可发布的深度思考文章。

**执行流程：**

```
触发事件 → 深度研究（Agent） → 结构设计 → 起草 → 审查 → 润色 → 输出
```

**三轮修订：**

| 阶段 | 说明 |
|------|------|
| 4a 起草 | 案例驱动写作，保存到 `writing-drafts/` |
| 4b 审查 | 分级审查（Critical/Significant/Minor）+ AI 去痕扫描 |
| 4c 润色 | 标题、开头钩子、金句、节奏检查 |

**新增能力（v2.0.0）：**

| 能力 | 说明 |
|------|------|
| 解耦语雀 | 默认输出 markdown 文件，语雀作为可选插件 |
| AI 去痕审查 | 扫描 50+ 中文 AI 写作指纹模式，逐项标记并建议替换 |
| 文风档案 | 从 2-3 篇用户文章中学习文风，保存到 `.claude/writing-voice.json` |
| 分级修订流程 | 起草 → 审查 → 润色三轮迭代 |

**使用示例：**

```bash
/深度写作 AI依赖悖论
/深度写作 话题=Vibe Coding的风险 风格=行业观察
/深度写作 自动化运维的陷阱 --output clipboard
/深度写作 话题=AI工具选择 风格=技术反思 --publish yuque
```
