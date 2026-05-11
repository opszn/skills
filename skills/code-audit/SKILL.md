---
name: code-audit
description: "When the user asks for code review, audit, security review, code quality analysis, or mentions issues like '代码审查', '安全审计', '代码质量', '找问题'. Supports scoped scanning (smart top-20 / directory / diff / full), four audit modes (quick/full/security/quality), confidence-filtered findings with SARIF output."
version: 1.0.0
license: MIT
author: opszn
user-invocable: true
tags: [code-review, security, audit, quality, sast]
compatibility: [claude-code]
---

# Code Audit

对任意项目进行系统性代码审计。覆盖安全、架构、质量、性能四个维度。

## 触发条件

用户提到以下关键词时自动触发：code review, audit, security review, code quality, 代码审查, 安全审计, 代码质量, 找问题, 检查代码
用户手动调用：`/code-audit`

## 作用域控制

```
/code-audit                    # 默认：智能扫描 Top 20 最大文件 + 入口文件
/code-audit --scope src/       # 只审指定目录
/code-audit --scope main.js    # 只审指定文件
/code-audit --diff             # 只审最近 5 个 commit 的变更
/code-audit --full             # 强制全量（所有源文件）
/code-audit --sarif            # 同时输出 SARIF 2.1 JSON
/code-audit --output report.md # 保存到指定路径（默认 .claude/audit-reports/）
/code-audit --verify           # 验证上次审计的所有发现
/code-audit --verify --finding 1 # 验证指定编号的发现
/code-audit --sast             # 仅执行 SAST 扫描，不做 grep 审计
```

**智能扫描逻辑（默认模式）**：

1. `find` 获取所有源文件，排除 `node_modules/.git/dist/build/vendor`
2. `wc -l` 排序取 Top 20 最大文件
3. 识别入口文件：`main.js`、`app.py`、`app/main.py`、`cmd/`、`bin/`、`index.ts`、`src/main.*`
4. 去重合并后优先审计这些文件
5. 总文件 >100 时提示用户："项目较大（X 个文件），当前智能扫描覆盖 Top 20 + 入口。如需全量审计，请使用 `--full`"

**--diff 模式**：`git diff --name-only HEAD~5` 获取变更文件，仅审计这些

## 审计模式

根据用户需求选择模式，默认 `full`：

| 模式 | 触发关键词 | 深度 | 耗时 |
|------|-----------|------|------|
| `quick` | 快速审计、快扫、看看有没有明显问题 | 多语言 grep + 结构分析 | < 2 分钟 |
| `full` | 完整审计、全面检查、深度审计 | 智能扫描 + 数据流 + 架构 | 5-15 分钟 |
| `security` | 安全审计、安全扫描、安全审查 | OWASP Top 10 专项 + SAST | 5-10 分钟 |
| `quality` | 质量审计、代码质量、找坏味道 | 质量专项检查 | 3-8 分钟 |

## 审计流程

### Phase 0: 作用域解析

解析用户传入的 `--scope` / `--diff` / `--full` / `--sarif` 参数，确定审计范围。

### Phase 1: 项目画像（所有模式）

```bash
# 项目结构
find . -type f \( -name '*.js' -o -name '*.ts' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.java' \) \
  ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/dist/*' ! -path '*/build/*' ! -path '*/vendor/*' \
  | head -200

# 文件规模（取 Top 20）
find . -type f \( -name '*.js' -o -name '*.ts' -o -name '*.py' -o -name '*.go' -o -name '*.rs' \) \
  ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/dist/*' ! -path '*/build/*' ! -path '*/vendor/*' \
  -exec wc -l {} + 2>/dev/null | sort -n | tail -20

# 依赖
cat package.json requirements.txt go.mod Cargo.toml pom.xml Gemfile 2>/dev/null | head -50
```

### Phase 1.5: SAST 工具执行（security / full 模式，--sast 模式）

执行可用的 SAST 工具并解析结构化结果：

```bash
# Node.js — 捕获 JSON 输出
if [ -f package-lock.json ]; then
  npm audit --omit=dev --json 2>/dev/null
elif [ -f yarn.lock ]; then
  yarn audit --groups dependencies --json 2>/dev/null
fi

# semgrep（通用，任何语言）
if command -v semgrep &>/dev/null; then
  semgrep scan --config=auto --json --quiet 2>/dev/null
fi

# Python
if [ -f requirements.txt ]; then
  if command -v pip-audit &>/dev/null; then
    pip-audit --format=json 2>/dev/null
  elif command -v safety &>/dev/null; then
    safety check --json 2>/dev/null
  fi
fi

# Go
if [ -f go.mod ]; then
  if command -v govulncheck &>/dev/null; then
    govulncheck ./... 2>&1
  else
    go vet ./... 2>&1
  fi
fi

# Rust
if [ -f Cargo.lock ] && command -v cargo-audit &>/dev/null; then
  cargo audit 2>&1
fi
```

**结果解析**：

- `npm audit --json` → 解析 `metadata.critical`、`metadata.high`、`vulnerabilities` keys
- `semgrep --json` → 解析 `results[]` 中的 `rule`、`severity`、`path`、`start.line`
- `pip-audit --json` → 解析依赖漏洞列表
- `govulncheck` / `go vet` → 解析文本输出中的 `vuln` / 包名
- `cargo audit` → 解析 `vulnerabilities` 数组

**报告合并**：将解析后的结构化结果作为"依赖安全"部分并入审计报告。格式：

```markdown
### 依赖安全
- npm audit: CRITICAL X, HIGH Y (Z 个已知漏洞)
- semgrep: N 条告警（M 条 CRITICAL）
- 未检测到 pip-audit，建议安装: `pip install pip-audit`
```

若所有工具均未安装，在报告中标注"未安装 SAST 工具，建议安装 `npm audit`（Node.js 自带）或 `semgrep`（通用）"。

如用户使用 `--sast` 模式，则跳过 grep 审计，仅执行本阶段 SAST 扫描。

### Phase 2: 模式专项检查

#### quick 模式 — 多语言快速扫描

按语言分组执行 grep，快速发现明显问题：

**JS/TS 组**：
```bash
# 危险函数
grep -rn 'eval(\|Function(\|exec(\|execSync(\|spawnSync(' --include='*.js' --include='*.ts' --include='*.jsx' --include='*.tsx' . 2>/dev/null
# XSS 风险
grep -rn 'innerHTML\|dangerouslySetInnerHTML\|outerHTML\|insertAdjacentHTML\|document\.write' --include='*.js' --include='*.ts' --include='*.jsx' --include='*.tsx' . 2>/dev/null
# 路径操作
grep -rn 'shell\.openPath\|__dirname.*user\|path\.join.*req' --include='*.js' --include='*.ts' . 2>/dev/null
# 同步阻塞
grep -rn 'readFileSync\|writeFileSync\|readdirSync\|statSync' --include='*.js' --include='*.ts' . 2>/dev/null | wc -l
# 空 catch
grep -rn 'catch.*{}' --include='*.js' --include='*.ts' . 2>/dev/null | head -20
```

**Python 组**：
```bash
# 代码注入
grep -rn 'eval(\|exec(\|compile(' --include='*.py' . 2>/dev/null
# 反序列化
grep -rn 'pickle\.load\|yaml\.load(\|marshal\.loads' --include='*.py' . 2>/dev/null
# 命令注入
grep -rn 'os\.system(\|subprocess\.call(.*shell=True\|subprocess\.Popen(.*shell=True' --include='*.py' . 2>/dev/null
# SQL 注入
grep -rn '\.execute(.*f["\x27]\|\.execute(.*%.*\|\.execute(.*+' --include='*.py' . 2>/dev/null
# 硬编码密钥
grep -rn 'password\s*=\s*["\x27][^"\x27]\{3,\}["\x27]\|secret\s*=\s*["\x27][^"\x27]\{3,\}["\x27]' --include='*.py' . 2>/dev/null | grep -v test
```

**Go 组**：
```bash
# 命令注入
grep -rn 'exec\.Command(.*Sprintf\|exec\.Command(.*+\|exec\.Command(.*fmt\.' --include='*.go' . 2>/dev/null
# SQL 注入
grep -rn '\.Query(.*Sprintf\|\.Exec(.*Sprintf\|\.Query(.*+' --include='*.go' . 2>/dev/null
# 不安全的反序列化
grep -rn 'json\.Unmarshal\|xml\.Unmarshal\|gob\.Decode' --include='*.go' . 2>/dev/null | head -20
# unsafe 操作
grep -rn 'unsafe\.Pointer\|unsafe\.Sizeof' --include='*.go' . 2>/dev/null
```

**跨语言（所有）**：
```bash
# 硬编码密钥
grep -rn 'api_key\s*=\s*["\x27][A-Za-z0-9]\{10,\}["\x27]\|API_KEY\s*=\s*["\x27][A-Za-z0-9]\{10,\}["\x27]' --include='*.js' --include='*.ts' --include='*.py' --include='*.go' --include='*.env' . 2>/dev/null | grep -v 'test\|spec\|example\|placeholder\|TODO\|CHANGE_ME\|your_\|xxx'
# CSP / 安全配置
grep -rn 'Content-Security-Policy\|sandbox.*false\|nodeIntegration.*true\|webSecurity.*false' --include='*.js' --include='*.ts' --include='*.py' --include='*.go' . 2>/dev/null
```

对 grep 结果逐条分析，标记误报。

#### full 模式 — 深度审计

在 quick 模式基础上，增加智能扫描文件的深度分析：

1. **数据流分析**: 追踪用户输入（URL params、表单、IPC 参数、API 请求体、CLI 参数）如何流到敏感操作（fs、child_process、exec、网络请求、数据库）。读关键文件的 Top 20 文件内容，追踪 tainted data flow
2. **架构审查**: 识别 God Object（>1500 行单文件）、循环依赖（import/require 环）、缺失分层（UI 直接调 DB）
3. **性能分析**: 识别 O(n²) 循环（嵌套 for/while 中的线性查找）、未缓存的重计算、缺失 debounce/throttle、过度 DOM 操作
4. **错误处理覆盖**: 统计 try/catch 比例、识别吞异常的 catch、无错误传播的 async 调用、无超时保护的 I/O
5. **命名一致性**: 同一概念是否多种命名、缩写是否统一、布尔变量是否以 is/has/can 开头

#### security 模式 — OWASP Top 10 专项

加载 `references/security-checklist.md` 逐项检查，结合 SAST 结果：

1. **A01: 注入** — SQL、命令、HTML、模板、反序列化
2. **A02: 认证失败** — 硬编码凭据、弱加密、会话管理、JWT 配置
3. **A03: 数据泄露** — 敏感信息日志打印、未加密传输、错误详情暴露
4. **A04: 不安全设计** — 缺少速率限制、CSRF 保护、幂等性
5. **A05: 安全配置缺失** — CSP、sandbox、CORS、HTTPS、安全 headers
6. **A06: 脆弱组件** — SAST 结果 + 过期依赖 + 已知 CVE
7. **A07: 认证与访问控制** — 越权操作、未验证角色、水平越权
8. **A08: 软件与数据完整性** — CI/CD 管道安全、签名验证、序列化
9. **A09: 安全日志与监控** — 空 catch、无错误上报、安全事件无审计
10. **A10: SSRF** — 用户可控 URL 请求、内网地址访问

#### quality 模式 — 代码质量专项

加载 `references/quality-checklist.md` 逐项检查：

1. **死代码** — 定义但未调用的函数、未使用的变量/import、注释掉的代码块
2. **重复代码** — 相同逻辑在多个文件出现（>10 行相似）
3. **命名不一致** — 同一概念多种命名、缩写混乱、布尔命名不规范
4. **错误处理** — 空 catch、吞异常、无错误传播、无 fallback
5. **大文件** — >1000 行需拆分、>2000 行必须拆分、函数 >50 行
6. **同步阻塞** — 主线程/事件循环上的同步 I/O、无异步化
7. **性能** — O(n²) 循环、未缓存重计算、过度重绘、无虚拟列表
8. **复杂度** — 嵌套 >4 层、圈复杂度 >10、函数参数 >5

### Phase 3: 发现过滤与去重

输出前执行：

1. **置信度过滤**: 每条发现评估置信度 0-100
   - < 80 → 自动过滤，不输出
   - >= 80 → 保留
2. **去重合并**: 同一问题类型在多个文件中出现 → 合并为一条，标注"影响 N 个文件"，仅列出 Top 3 具体位置
3. **测试文件标注**: 仅在 test/spec 文件中发现的问题 → 标注为 `TEST_SCOPE`，单独列出，不计入安全评分
4. **排序**: 按严重度（CRITICAL > HIGH > MEDIUM > LOW），同严重度按置信度降序

### Phase 4: 输出审计报告

**持久化报告路径计算**（审计开始时执行）：

```bash
REPORT_DATE=$(date +%Y%m%d-%H%M%S)
REPORT_DIR=".claude/audit-reports"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/audit-report-$REPORT_DATE.md"
```

**输出到对话**后，将完整报告内容写入 `$REPORT_FILE`，并更新 `$REPORT_DIR/audit-latest.md` 为最新报告的副本：

```bash
# 写入报告文件
# （将审计报告全文写入 $REPORT_FILE）

# 维护 latest 副本
cp "$REPORT_FILE" "$REPORT_DIR/audit-latest.md" 2>/dev/null

# 如用户指定了 --output 路径，额外复制
if [ -n "$OUTPUT_PATH" ]; then
  cp "$REPORT_FILE" "$OUTPUT_PATH"
fi
```

如果用户使用了 `--output <path>` 参数，额外将报告保存到指定路径。

```markdown
## 代码审计报告 — {项目名} — {日期}

### 项目画像
- 审计范围: {scope 描述}
- 总文件: X（智能扫描: Top N 最大文件 + 入口文件）| 总行数: X
- 主要语言: {languages}
- 依赖数: X | SAST 告警: X

### 发现 (CRITICAL + HIGH)

| # | 严重度 | 置信度 | CWE | 文件:行号 | 问题 | 利用场景 | 修复 | 工时 |
|---|--------|--------|-----|-----------|------|----------|------|------|
| 1 | CRITICAL | 95 | CWE-22 | main.js:912 | 路径遍历 | 用户输入 ../../etc/passwd 读取任意文件 | path.resolve + startsWith 校验 | <15min |

### 发现 (MEDIUM + LOW)

| # | 严重度 | 置信度 | CWE | 文件:行号 | 问题 | 修复 | 工时 |
|---|--------|--------|-----|-----------|------|------|------|

### 依赖安全
{SAST 工具结果摘要，或"未检测到已知漏洞"}

### 统计
- CRITICAL: X | HIGH: X | MEDIUM: X | LOW: X
- 置信度过滤: X 条低于 80，已自动过滤
- 去重合并: X 条相似问题合并为 Y 条
- 安全评分: X/100 | 质量评分: X/100

### 修复路线图
1. **立即修复** (CRITICAL, 预计 X 小时): ...
2. **本迭代修复** (HIGH, 预计 X 小时): ...
3. **规划修复** (MEDIUM, 预计 X 小时): ...
4. **优化建议** (LOW): ...
```

### SARIF 输出 (--sarif 模式)

同时输出 SARIF 2.1.0 格式 JSON，可直接接入 CI/CD：

```json
{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [{
    "tool": { "driver": { "name": "claude-code-audit", "version": "1.0.0", "informationUri": "https://github.com/lingsheng/claude-code-audit" } },
    "results": [{
      "ruleId": "CWE-22",
      "level": "error",
      "message": { "text": "路径遍历：open-file handler 无路径验证" },
      "locations": [{
        "physicalLocation": {
          "artifactLocation": { "uri": "main.js" },
          "region": { "startLine": 912 }
        }
      }]
    }]
  }]
}
```

### Phase 5: 修复验证（--verify 模式）

当用户使用 `--verify` 参数时，执行此阶段：

1. 读取 `.claude/audit-reports/audit-latest.md`，解析发现列表（表格中的 # 编号、CWE、文件:行号、问题类型）
2. 针对每条发现重新执行对应的 grep 检查：

| CWE 类型 | 验证命令 | 判定标准 |
|----------|----------|----------|
| CWE-22 路径遍历 | `grep -n 'path\.resolve\|startsWith\|realpath' <file>` | 包含校验逻辑 → FIXED |
| CWE-79 XSS | `grep -n 'innerHTML\|dangerouslySetInnerHTML\|document\.write' <file>` | 无直接赋值或已 sanitize → FIXED |
| CWE-78 命令注入 | `grep -n 'exec(\|execSync(\|spawn.*shell.*true' <file>` | 使用参数数组/无拼接 → FIXED |
| CWE-89 SQL 注入 | `grep -n '\.query(.*\+\|\.execute(.*\+\|\.query(.*Sprintf' <file>` | 使用参数化查询 → FIXED |
| CWE-798 硬编码密钥 | `grep -n 'password.*=.*["\x27]\|secret.*=.*["\x27]\|api_key.*=.*["\x27]' <file>` | 无硬编码匹配 → FIXED |
| CWE-391 空 catch | `grep -n 'catch.*{}' <file>` | 无空 catch → FIXED |

3. 如用户使用 `--verify --finding <N>`，只验证指定编号的发现

输出格式：

```markdown
### 修复验证结果

| 编号 | CWE | 问题 | 文件 | 状态 | 详情 |
|------|-----|------|------|------|------|
| #1 | CWE-22 | 路径遍历 | main.js | FIXED | 已添加 path.resolve + startsWith 校验 |
| #2 | CWE-79 | XSS | app.js | FAILING | line 1024 仍存在 innerHTML 直接赋值 |
```

状态定义：
- `FIXED`：原问题已修复，grep 未命中或校验逻辑存在
- `FAILING`：原问题仍存在，grep 命中相同模式
- `MODIFIED`：代码有变化但无法自动判定，需人工复核

## 严重度定义

| 严重度 | 定义 | 示例 | CWE 参考 |
|--------|------|------|----------|
| CRITICAL | 可被外部利用的安全漏洞，直接导致数据泄露、RCE 或完整系统接管 | 路径遍历、XSS、命令注入、SQL 注入、硬编码密钥 | CWE-22, CWE-79, CWE-78, CWE-89, CWE-798 |
| HIGH | 高风险问题，可能被利用或导致数据损坏/服务不可用 | 绕过式路径验证、markdown XSS、无 CSP、未加密传输 | CWE-601, CWE-79, CWE-693, CWE-319 |
| MEDIUM | 影响质量或性能的问题，不会直接被外部利用 | 空 catch 吞异常、大文件、同步阻塞、重复代码 | CWE-391, CWE-1079, CWE-400 |
| LOW | 代码风格或优化建议 | 命名不一致、缺少注释、魔法数字 | CWE-1076 |

## 置信度评分参考

| 分数 | 含义 |
|------|------|
| 95-100 | 明确的漏洞，可直接利用，无误报 |
| 85-94 | 高概率问题，需要少量上下文确认 |
| 80-84 | 可能是问题，需要人工复核 |
| < 80 | 可能误报，自动过滤 |

## 注意事项

- 不要修改用户代码，仅输出报告
- 对于 --diff 模式，关注变更引入的新问题，不报告已有的
- 审计 Web 项目时，额外检查 CSP、CORS、HTTPS 配置
- 审计 Electron/桌面应用时，额外关注 main/preload/renderer 安全边界
- 审计 CLI 项目时，检查参数解析、错误退出码、管道安全
- 大项目（>100 文件）默认智能扫描，提示用户可用 --full 全量审计
