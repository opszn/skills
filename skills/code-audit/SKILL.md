---
name: code-audit
description: "When the user asks for code review, audit, security review, code quality analysis, or mentions issues like '代码审查', '安全审计', '代码质量', '找问题'. Supports quick scan, full audit, security focus, and quality focus modes."
version: 1.0.0
license: MIT
user-invocable: true
---

# Code Audit

对任意项目进行系统性代码审计。覆盖安全、架构、质量、性能四个维度。

## 触发条件

用户提到以下关键词时自动触发：code review, audit, security review, code quality, 代码审查, 安全审计, 代码质量, 找问题, 检查代码
用户手动调用：`/code-audit`

## 审计模式

根据用户需求选择模式，默认 `full`：

| 模式 | 触发关键词 | 深度 | 耗时 |
|------|-----------|------|------|
| `quick` | 快速审计、快扫、看看有没有明显问题 | 浅层 grep + 结构分析 | < 2 分钟 |
| `full` | 完整审计、全面检查、深度审计 | 全量分析 | 5-15 分钟 |
| `security` | 安全审计、安全扫描、安全审查 | OWASP Top 10 专项 | 5-10 分钟 |
| `quality` | 质量审计、代码质量、找坏味道 | 质量专项检查 | 3-8 分钟 |

## 审计流程

### Phase 1: 项目画像（所有模式）

```bash
# 项目结构
find . -type f \( -name '*.js' -o -name '*.ts' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.java' \) \
  ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/dist/*' ! -path '*/build/*' ! -path '*/vendor/*' \
  | head -200

# 文件规模
wc -l $(find . -type f \( -name '*.js' -o -name '*.ts' -o -name '*.py' -o -name '*.go' \) \
  ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/dist/*' ! -path '*/build/*') 2>/dev/null | sort -n | tail -20

# 依赖
cat package.json requirements.txt go.mod Cargo.toml 2>/dev/null | head -50
```

### Phase 2: 模式专项检查

#### quick 模式 — 快速扫描

执行以下 grep 命令，输出命中的文件和行号：

```bash
# 危险函数
grep -rn 'eval(\|Function(\|exec(\|execSync(\|spawnSync(' --include='*.js' --include='*.ts' --include='*.py' . 2>/dev/null

# 未转义的 innerHTML / XSS 风险
grep -rn 'innerHTML\|dangerouslySetInnerHTML\|outerHTML\|insertAdjacentHTML\|document\.write' --include='*.js' --include='*.ts' --include='*.jsx' --include='*.tsx' . 2>/dev/null

# 硬编码密钥
grep -rn 'password.*=.*["\x27]\|secret.*=.*["\x27]\|token.*=.*["\x27]\|api_key.*=.*["\x27]\|API_KEY.*=.*["\x27]' --include='*.js' --include='*.ts' --include='*.py' --include='*.env' . 2>/dev/null | grep -v 'test\|spec\|example\|placeholder\|TODO'

# 路径遍历风险
grep -rn 'fs\.readFile\|fs\.readFileSync\|fs\.writeFile\|fs\.writeFileSync' --include='*.js' --include='*.ts' . 2>/dev/null | grep -v 'node_modules'

# 同步阻塞
grep -rn 'readFileSync\|writeFileSync\|readdirSync\|statSync\|existsSync' --include='*.js' --include='*.ts' . 2>/dev/null | wc -l

# 空 catch
grep -rn 'catch.*{}\|catch.*{ *}' --include='*.js' --include='*.ts' --include='*.py' . 2>/dev/null | head -20

# 未使用的 import
grep -rn '^import\|^require' --include='*.js' --include='*.ts' . 2>/dev/null | head -50
```

#### full 模式 — 深度审计

在 quick 模式基础上，增加：

1. **数据流分析**: 追踪用户输入（URL params、表单、IPC 参数、API 请求体）如何流到敏感操作（fs、child_process、网络请求、数据库）
2. **架构审查**: 识别 God Object（>1500 行单文件）、循环依赖、缺失分层
3. **性能分析**: 识别 O(n²) 循环、未缓存的重计算、缺失 debounce/throttle、过度 DOM 操作
4. **错误处理覆盖**: 统计 try/catch 比例、识别吞异常的 catch、无错误传播的 async 调用
5. **命名一致性**: 同一概念是否多种命名、缩写是否统一

#### security 模式 — OWASP Top 10 专项

加载 `references/security-checklist.md` 逐项检查：

1. **A01: 注入** — SQL、命令、HTML、模板注入
2. **A02: 认证失败** — 硬编码凭据、弱加密、会话管理
3. **A03: 数据泄露** — 敏感信息日志打印、未加密传输
4. **A04: XML 外部实体** — XML 解析配置
5. **A05: 访问控制缺失** — 越权操作、未验证角色
6. **A06: 安全配置** — CSP、sandbox、CORS、headers
7. **A07: XSS** — innerHTML、markdown 未消毒、模板注入
8. **A08: 反序列化** — JSON.parse 用户输入、pickle.load
9. **A09: 已知漏洞组件** — 过期依赖、已知 CVE
10. **A10: 日志监控不足** — 空 catch、无错误上报

#### quality 模式 — 代码质量专项

加载 `references/quality-checklist.md` 逐项检查：

1. **死代码** — 定义但未调用的函数、未使用的变量/import
2. **重复代码** — 相同逻辑在多个文件出现
3. **命名不一致** — 同一概念多种命名、缩写混乱
4. **错误处理** — 空 catch、吞异常、无错误传播
5. **大文件** — >1000 行需拆分、>2000 行必须拆分
6. **同步阻塞** — 主线程/事件循环上的同步 I/O
7. **性能** — O(n²) 循环、未缓存重计算、过度重绘
8. **复杂度** — 嵌套 >4 层、函数 >50 行、条件分支 >10

### Phase 3: 输出审计报告

按以下格式输出：

```markdown
## 代码审计报告 — {项目名}

### 项目画像
- 总文件: X | 总行数: X
- 最大文件: {path} (X 行)
- 主要语言: {languages}
- 依赖数: X | 已知漏洞依赖: X

### 发现 (按严重度排序)

| # | 严重度 | 文件:行号 | 问题类型 | 描述 | 修复建议 |
|---|--------|-----------|----------|------|----------|
| 1 | CRITICAL | main.js:912 | 路径遍历 | open-file 无路径验证 | 使用 path.resolve + startsWith 校验 |

### 统计
- CRITICAL: X | HIGH: X | MEDIUM: X | LOW: X
- 安全评分: X/100
- 质量评分: X/100

### 修复优先级
1. **立即修复** (CRITICAL): ...
2. **本迭代修复** (HIGH): ...
3. **规划修复** (MEDIUM): ...
4. **优化建议** (LOW): ...
```

### 严重度定义

| 严重度 | 定义 | 示例 |
|--------|------|------|
| CRITICAL | 可被利用的安全漏洞，直接导致数据泄露或远程代码执行 | 路径遍历、XSS、命令注入 |
| HIGH | 高风险问题，可能被利用或导致数据损坏 | 硬编码密钥、绕过式路径验证 |
| MEDIUM | 影响质量或性能的问题，不会直接被利用 | 空 catch、大文件、重复代码 |
| LOW | 代码风格或优化建议 | 命名不一致、缺少注释 |

## 注意事项

- 对于大项目（>100 个源文件），先确认用户是否需要全量审计
- 审计 Electron 类项目时，额外关注 main/preload/renderer 安全边界
- 审计 Web 项目时，检查 CSP、CORS、HTTPS 配置
- 审计 CLI 项目时，检查参数解析、错误退出码、管道安全
- 不要修改用户代码，仅输出报告
