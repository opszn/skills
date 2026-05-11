# AI Dev Skills

Claude Code 双技能插件 — 代码审计 + 功能测试，适用于任意编程语言的 Web、桌面和 CLI 应用。

## 安装

### 方式一：从 GitHub 安装（推荐）

```
/plugin install github:lingsheng/ai-dev-skills
```

### 方式二：本地安装

```bash
git clone https://github.com/lingsheng/ai-dev-skills.git
cd ai-dev-skills
/plugin install ./
```

### 方式三：手动安装

将 `skills/` 目录复制到项目的 `.claude/skills/` 下：

```bash
cp -r skills/code-audit ~/.claude/skills/
cp -r skills/functional-test ~/.claude/skills/
```

## 技能列表

### `/code-audit` — 代码审计

对任意项目进行系统性代码审计，覆盖安全、架构、质量、性能四个维度。

**四种审计模式：**

| 模式 | 适用场景 | 耗时 |
|------|----------|------|
| `quick` | 快速扫描明显问题 | < 2 分钟 |
| `full` | 全面深度审计（默认） | 5-15 分钟 |
| `security` | OWASP Top 10 安全专项 | 5-10 分钟 |
| `quality` | 代码质量专项 | 3-8 分钟 |

**使用示例：**

```
/code-audit                    # 完整审计当前项目
/code-audit --quick            # 快速扫描
/code-audit --security         # 安全专项审计
/code-audit --verify           # 验证上次审计的修复结果
/code-audit --sast             # 仅执行 SAST 依赖扫描
帮我审计一下这个项目的代码      # 自然语言触发
```

**输出：** 严重度分级发现列表 + 项目画像 + 修复优先级建议

**新增能力（v1.1.0）：**

| 能力 | 说明 |
|------|------|
| 持久化报告 | 审计结果自动保存到 `.claude/audit-reports/` |
| 修复验证 | `/code-audit --verify` 验证问题是否已修复 |
| SAST 自动执行 | 自动检测并运行 npm audit / semgrep / pip-audit / govulncheck |

### `/functional-test` — 功能测试

生成测试计划、执行功能测试、产出测试报告。

**四种工作模式：**

| 模式 | 说明 |
|------|------|
| `plan` | 分析应用结构，生成测试矩阵 |
| `execute` | 按测试计划逐项执行 |
| `regression` | 重新运行历史测试，对比结果 |
| `report` | 生成测试总结报告 |

**使用示例：**

```
/functional-test               # 生成测试计划并执行
/functional-test --plan        # 仅生成测试计划
/functional-test --regression  # 回归测试
帮这个应用做个功能测试           # 自然语言触发
```

**覆盖维度：** Golden Path / Edge Cases / Regression / UI-UX / Performance Baseline

## 项目结构

```
ai-dev-skills/
├── .claude-plugin/
│   ├── plugin.json           # 插件元数据
│   └── marketplace.json      # Marketplace 注册信息
├── README.md                 # 本文件
├── LICENSE                   # MIT
├── skills/
│   ├── code-audit/
│   │   ├── SKILL.md          # 代码审计技能主文件
│   │   ├── scripts/          # 辅助脚本
│   │   │   ├── run-sast.sh       # SAST 自动执行
│   │   │   └── verify-finding.sh # 修复验证
│   │   └── references/       # 检查清单（审计时自动加载）
│   │       ├── security-checklist.md   # OWASP Top 10 安全检查
│   │       └── quality-checklist.md    # 代码质量检查
│   └── functional-test/
│       ├── SKILL.md          # 功能测试技能主文件
│       └── references/       # 模板（测试时自动加载）
│           ├── test-plan-template.md   # 按应用类型的测试计划模板
│           └── bug-report-template.md  # Bug 报告模板
└── docs/
    └── changelog.md          # 版本历史
```

## 贡献

欢迎提交 Issue 和 Pull Request。

### 新增技能
1. 在 `skills/` 下创建新目录
2. 创建 `SKILL.md`，包含 YAML frontmatter
3. 在 `references/` 下添加参考文档
4. 更新 `.claude-plugin/marketplace.json`

### 改进现有技能
1. SKILL.md 保持在 500 行以内
2. 详细内容放到 `references/` 目录
3. 更新 `docs/changelog.md`

## License

[MIT](LICENSE)
