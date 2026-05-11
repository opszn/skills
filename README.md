# AI Dev Skills

Claude Code skills plugin — **code audit** + **functional testing**, for web, desktop and CLI applications in any programming language.

[中文文档](#中文文档)

## Installation

### Method 1: From GitHub (Recommended)

```bash
/plugin install github:opszn/claude-code-audit
```

### Method 2: Local Install

```bash
git clone https://github.com/opszn/claude-code-audit.git
cd claude-code-audit
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

**Four work modes:**

| Mode | Description |
|------|-------------|
| `plan` | Analyze app structure, generate test matrix |
| `execute` | Execute tests from plan |
| `regression` | Re-run historical tests, compare results |
| `report` | Generate test summary report |

**Examples:**

```bash
/functional-test               # Generate plan and execute
/functional-test --plan        # Generate plan only
/functional-test --regression  # Regression test
```

**Coverage:** Golden Path / Edge Cases / Regression / UI-UX / Performance Baseline

## Project Structure

```
ai-dev-skills/
├── .claude-plugin/
│   ├── plugin.json           # Plugin metadata
│   └── marketplace.json      # Marketplace registration
├── README.md                 # This file
├── LICENSE                   # MIT
├── skills/
│   ├── code-audit/
│   │   ├── SKILL.md          # Code audit skill
│   │   ├── scripts/          # Helper scripts
│   │   │   ├── run-sast.sh       # SAST auto-execution
│   │   │   └── verify-finding.sh # Fix verification
│   │   └── references/       # Checklists
│   │       ├── security-checklist.md   # OWASP Top 10
│   │       └── quality-checklist.md    # Code quality
│   └── functional-test/
│       ├── SKILL.md          # Functional test skill
│       └── references/       # Templates
│           ├── test-plan-template.md   # Test plan templates
│           └── bug-report-template.md  # Bug report template
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
/plugin install github:opszn/claude-code-audit
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

**覆盖维度：** Golden Path / Edge Cases / Regression / UI-UX / Performance Baseline
