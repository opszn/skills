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

# Code Audit / 代码审计

Systematic code audit for any project, covering security, architecture, quality, and performance.
对任意项目进行系统性代码审计，覆盖安全、架构、质量、性能四个维度。

## Trigger Conditions / 触发条件

Auto-trigger on: code review, audit, security review, code quality, 代码审查, 安全审计, 代码质量, 找问题
Manual: `/code-audit`

## Scope Control / 作用域控制

```
/code-audit                    # Default: Smart scan — Top 20 largest + entry points
/code-audit --scope src/       # Audit specific directory
/code-audit --scope main.js    # Audit specific file
/code-audit --diff             # Audit last 5 commits only
/code-audit --full             # Full audit (all source files)
/code-audit --sarif            # Also output SARIF 2.1 JSON
/code-audit --output report.md # Save to custom path (default: .claude/audit-reports/)
/code-audit --verify           # Verify all findings from last audit
/code-audit --verify --finding 1 # Verify a specific finding by ID
/code-audit --sast             # SAST-only scan, skip grep audit
```

**Smart Scan (default mode)**:
1. `find` all source files, excluding `node_modules/.git/dist/build/vendor`
2. `wc -l` sort, take Top 20 largest
3. Identify entry points: `main.js`, `app.py`, `app/main.py`, `cmd/`, `bin/`, `index.ts`, `src/main.*`
4. Deduplicate and audit these files first
5. If total files > 100, prompt: "Project is large (X files). Smart scan covers Top 20 + entries. Use `--full` for full audit."

**--diff mode**: `git diff --name-only HEAD~5` to get changed files, audit only those

## Audit Modes / 审计模式

Default: `full`

| Mode | Trigger Keywords | Depth | Time |
|------|-----------------|-------|------|
| `quick` | 快速审计, 快扫, quick scan | Multi-language grep + structure | < 2 min |
| `full` | 完整审计, 全面检查, deep audit | Smart scan + dataflow + architecture | 5-15 min |
| `security` | 安全审计, security review | OWASP Top 10 + SAST | 5-10 min |
| `quality` | 质量审计, 坏味道, code quality | Quality checklist | 3-8 min |

## Audit Workflow / 审计流程

### Phase 0: Scope Resolution

Parse `--scope` / `--diff` / `--full` / `--sarif` parameters to determine audit scope.

### Phase 1: Project Profile (all modes)

```bash
# Project structure
find . -type f \( -name '*.js' -o -name '*.ts' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.java' \) \
  ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/dist/*' ! -path '*/build/*' ! -path '*/vendor/*' \
  | head -200

# File sizes (Top 20)
find . -type f \( -name '*.js' -o -name '*.ts' -o -name '*.py' -o -name '*.go' -o -name '*.rs' \) \
  ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/dist/*' ! -path '*/build/*' ! -path '*/vendor/*' \
  -exec wc -l {} + 2>/dev/null | sort -n | tail -20

# Dependencies
cat package.json requirements.txt go.mod Cargo.toml pom.xml Gemfile 2>/dev/null | head -50
```

### Phase 1.5: SAST Execution (security / full modes, or --sast)

Run available SAST tools and parse structured results:

```bash
# Node.js
if [ -f package-lock.json ]; then
  npm audit --omit=dev --json 2>/dev/null
elif [ -f yarn.lock ]; then
  yarn audit --groups dependencies --json 2>/dev/null
fi

# semgrep (any language)
if command -v semgrep &>/dev/null; then
  semgrep scan --config=auto --json --quiet 2>/dev/null
fi

# Python
if [ -f requirements.txt ]; then
  if command -v pip-audit &>/dev/null; then pip-audit --format=json 2>/dev/null
  elif command -v safety &>/dev/null; then safety check --json 2>/dev/null; fi
fi

# Go
if [ -f go.mod ]; then
  if command -v govulncheck &>/dev/null; then govulncheck ./... 2>&1
  else go vet ./... 2>&1; fi
fi

# Rust
if [ -f Cargo.lock ] && command -v cargo-audit &>/dev/null; then cargo audit 2>&1; fi
```

**Result parsing**:
- `npm audit --json` → `metadata.critical`, `metadata.high`, `vulnerabilities` keys
- `semgrep --json` → `results[]` with `rule`, `severity`, `path`, `start.line`
- `pip-audit --json` → dependency vulnerability list
- `govulncheck` / `go vet` → parse text output for `vuln` / package names
- `cargo audit` → `vulnerabilities` array

**Merge into report**: Add a "Dependency Security" section. If no SAST tools available, note: "No SAST tools detected. Install `semgrep` (universal) for enhanced scanning."

`--sast` mode skips grep audit and runs only this phase.

### Phase 2: Mode-Specific Checks

#### quick Mode — Multi-language Fast Scan

Execute grep by language group:

**JS/TS**:
```bash
# Dangerous functions
grep -rn 'eval(\|Function(\|exec(\|execSync(\|spawnSync(' --include='*.js' --include='*.ts' --include='*.jsx' --include='*.tsx' . 2>/dev/null
# XSS risk
grep -rn 'innerHTML\|dangerouslySetInnerHTML\|outerHTML\|insertAdjacentHTML\|document\.write' --include='*.js' --include='*.ts' --include='*.jsx' --include='*.tsx' . 2>/dev/null
# Path operations
grep -rn 'shell\.openPath\|__dirname.*user\|path\.join.*req' --include='*.js' --include='*.ts' . 2>/dev/null
# Sync blocking
grep -rn 'readFileSync\|writeFileSync\|readdirSync\|statSync' --include='*.js' --include='*.ts' . 2>/dev/null | wc -l
# Empty catch
grep -rn 'catch.*{}' --include='*.js' --include='*.ts' . 2>/dev/null | head -20
```

**Python**:
```bash
# Code injection
grep -rn 'eval(\|exec(\|compile(' --include='*.py' . 2>/dev/null
# Deserialization
grep -rn 'pickle\.load\|yaml\.load(\|marshal\.loads' --include='*.py' . 2>/dev/null
# Command injection
grep -rn 'os\.system(\|subprocess\.call(.*shell=True' --include='*.py' . 2>/dev/null
# SQL injection
grep -rn '\.execute(.*f["\x27]\|\.execute(.*%.*\|\.execute(.*+' --include='*.py' . 2>/dev/null
# Hardcoded secrets
grep -rn 'password\s*=\s*["\x27][^"\x27]\{3,\}["\x27]\|secret\s*=\s*["\x27][^"\x27]\{3,\}["\x27]' --include='*.py' . 2>/dev/null | grep -v test
```

**Go**:
```bash
# Command injection
grep -rn 'exec\.Command(.*Sprintf\|exec\.Command(.*+' --include='*.go' . 2>/dev/null
# SQL injection
grep -rn '\.Query(.*Sprintf\|\.Exec(.*Sprintf\|\.Query(.*+' --include='*.go' . 2>/dev/null
# Unsafe
grep -rn 'unsafe\.Pointer\|unsafe\.Sizeof' --include='*.go' . 2>/dev/null
```

**Cross-language (all)**:
```bash
# Hardcoded API keys
grep -rn 'api_key\s*=\s*["\x27][A-Za-z0-9]\{10,\}["\x27]\|API_KEY\s*=\s*["\x27][A-Za-z0-9]\{10,\}["\x27]' --include='*.js' --include='*.ts' --include='*.py' --include='*.go' --include='*.env' . 2>/dev/null | grep -v 'test\|spec\|example\|placeholder\|TODO\|CHANGE_ME\|your_\|xxx'
# CSP / security config
grep -rn 'Content-Security-Policy\|sandbox.*false\|nodeIntegration.*true\|webSecurity.*false' --include='*.js' --include='*.ts' --include='*.py' --include='*.go' . 2>/dev/null
```

Analyze grep results line by line, flag false positives.

#### full Mode — Deep Audit

On top of quick mode, add:

1. **Dataflow Analysis**: Trace user input (URL params, forms, IPC params, API bodies, CLI args) to sensitive operations (fs, child_process, exec, network, DB). Read Top 20 key files, trace tainted data flow
2. **Architecture Review**: Identify God Objects (>1500 lines), circular dependencies (import/require cycles), missing layers (UI calling DB directly)
3. **Performance**: O(n²) loops (nested for/while with linear search), un-cached recomputation, missing debounce/throttle, excessive DOM ops
4. **Error Handling Coverage**: try/catch ratio, swallowed exceptions, async calls without error propagation, I/O without timeout protection
5. **Naming Consistency**: Same concept with different names, inconsistent abbreviations, boolean vars should start with is/has/can

#### security Mode — OWASP Top 10

Load `references/security-checklist.md`, combine with SAST results:

1. **A01: Injection** — SQL, command, HTML, template, deserialization
2. **A02: Broken Authentication** — hardcoded credentials, weak crypto, session management, JWT
3. **A03: Data Exposure** — sensitive info in logs, unencrypted transport, error details exposed
4. **A04: Insecure Design** — missing rate limiting, CSRF protection, idempotency
5. **A05: Security Misconfiguration** — CSP, sandbox, CORS, HTTPS, security headers
6. **A06: Vulnerable Components** — SAST results + outdated dependencies + known CVEs
7. **A07: Auth & Access Control** — privilege escalation, unverified roles, horizontal escalation
8. **A08: Integrity Failures** — CI/CD pipeline security, signature verification, serialization
9. **A09: Logging & Monitoring** — empty catch, no error reporting, no security event auditing
10. **A10: SSRF** — user-controlled URL requests, internal network access

#### quality Mode — Code Quality

Load `references/quality-checklist.md`:

1. **Dead Code** — defined but never called functions, unused variables/imports, commented-out code blocks
2. **Duplicate Code** — same logic across multiple files (>10 lines similar)
3. **Naming Inconsistency** — same concept multiple names, confusing abbreviations, boolean naming
4. **Error Handling** — empty catch, swallowed exceptions, no error propagation, no fallback
5. **Large Files** — >1000 lines should split, >2000 lines must split, functions >50 lines
6. **Sync Blocking** — sync I/O on main thread/event loop, no async
7. **Performance** — O(n²) loops, un-cached heavy computation, excessive re-renders, no virtual lists
8. **Complexity** — nesting >4 levels, cyclomatic complexity >10, function params >5

### Phase 3: Filtering & Deduplication

Before output:

1. **Confidence Filter**: Score each finding 0-100
   - < 80 → auto-filtered, not output
   - >= 80 → retained
2. **Deduplicate**: Same issue type across multiple files → merge into one, note "affects N files", list Top 3 locations only
3. **Test File Annotation**: Issues found only in test/spec files → labeled `TEST_SCOPE`, listed separately, excluded from security score
4. **Sort**: By severity (CRITICAL > HIGH > MEDIUM > LOW), then by confidence descending

### Phase 4: Output Report

**Persistent report path** (computed at audit start):

```bash
REPORT_DATE=$(date +%Y%m%d-%H%M%S)
REPORT_DIR=".claude/audit-reports"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/audit-report-$REPORT_DATE.md"
```

After outputting to conversation, write full report to `$REPORT_FILE`, and update `$REPORT_DIR/audit-latest.md` as a copy:

```bash
cp "$REPORT_FILE" "$REPORT_DIR/audit-latest.md" 2>/dev/null
if [ -n "$OUTPUT_PATH" ]; then cp "$REPORT_FILE" "$OUTPUT_PATH"; fi
```

```markdown
## Code Audit Report — {project} — {date}

### Project Profile
- Scope: {scope description}
- Total files: X (smart scan: Top N largest + entry points) | Total lines: X
- Languages: {languages}
- Dependencies: X | SAST alerts: X

### Findings (CRITICAL + HIGH)

| # | Severity | Confidence | CWE | File:Line | Issue | Exploit Scenario | Fix | Effort |
|---|----------|------------|-----|-----------|-------|------------------|-----|--------|
| 1 | CRITICAL | 95 | CWE-22 | main.js:912 | Path traversal | User input ../../etc/passwd reads arbitrary files | path.resolve + startsWith | <15min |

### Findings (MEDIUM + LOW)

| # | Severity | Confidence | CWE | File:Line | Issue | Fix | Effort |
|---|----------|------------|-----|-----------|-------|-----|--------|

### Dependency Security
{SAST tool summary, or "No vulnerabilities detected"}

### Statistics
- CRITICAL: X | HIGH: X | MEDIUM: X | LOW: X
- Confidence filtered: X findings below 80, auto-filtered
- Deduplication: X similar issues merged into Y
- Security score: X/100 | Quality score: X/100

### Remediation Roadmap
1. **Immediate** (CRITICAL, est. X hours): ...
2. **This sprint** (HIGH, est. X hours): ...
3. **Planned** (MEDIUM, est. X hours): ...
4. **Optimization** (LOW): ...
```

### SARIF Output (--sarif)

Also output SARIF 2.1.0 JSON for CI/CD integration:

```json
{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [{
    "tool": { "driver": { "name": "claude-code-audit", "version": "1.0.0", "informationUri": "https://github.com/opszn/skills" } },
    "results": [{
      "ruleId": "CWE-22",
      "level": "error",
      "message": { "text": "Path traversal: open-file handler lacks path validation" },
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

### Phase 5: Fix Verification (--verify)

When `--verify` is used:

1. Read `.claude/audit-reports/audit-latest.md`, parse findings table (# ID, CWE, file:line, issue type)
2. Re-run corresponding grep check for each finding:

| CWE Type | Verification Command |判定 |
|----------|---------------------|------|
| CWE-22 Path traversal | `grep -n 'path\.resolve\|startsWith\|realpath' <file>` | Validation logic present → FIXED |
| CWE-79 XSS | `grep -n 'innerHTML\|dangerouslySetInnerHTML\|document\.write' <file>` | No direct assignment or sanitized → FIXED |
| CWE-78 Command injection | `grep -n 'exec(\|execSync(\|spawn.*shell.*true' <file>` | Uses param array / no concat → FIXED |
| CWE-89 SQL injection | `grep -n '\.query(.*\+\|\.execute(.*\+\|\.query(.*Sprintf' <file>` | Uses parameterized queries → FIXED |
| CWE-798 Hardcoded secret | `grep -n 'password.*=.*["\x27]\|secret.*=.*["\x27]\|api_key.*=.*["\x27]' <file>` | No hardcoded match → FIXED |
| CWE-391 Empty catch | `grep -n 'catch.*{}' <file>` | No empty catch → FIXED |

3. If `--verify --finding <N>`, only verify that specific finding

Output:
```markdown
### Fix Verification Results

| ID | CWE | Issue | File | Status | Details |
|----|-----|-------|------|--------|---------|
| #1 | CWE-22 | Path traversal | main.js | FIXED | Added path.resolve + startsWith validation |
| #2 | CWE-79 | XSS | app.js | FAILING | line 1024 still has innerHTML direct assignment |
```

Status: `FIXED` (resolved), `FAILING` (still present), `MODIFIED` (changed but needs manual review)

## Severity Definitions / 严重度定义

| Severity | Definition | Example | CWE Ref |
|----------|-----------|---------|---------|
| CRITICAL | Exploitable security vulnerability, direct data leak / RCE / full system compromise | Path traversal, XSS, command injection, SQL injection, hardcoded secrets | CWE-22, CWE-79, CWE-78, CWE-89, CWE-798 |
| HIGH | High risk, may be exploitable or cause data corruption / service unavailability | Bypassed path validation, markdown XSS, no CSP, unencrypted transport | CWE-601, CWE-79, CWE-693, CWE-319 |
| MEDIUM | Quality/performance impact, not directly externally exploitable | Empty catch swallowing exceptions, large files, sync blocking, duplicate code | CWE-391, CWE-1079, CWE-400 |
| LOW | Code style or optimization suggestions | Naming inconsistency, missing comments, magic numbers | CWE-1076 |

## Confidence Scoring / 置信度评分

| Score | Meaning |
|-------|---------|
| 95-100 | Clear vulnerability, directly exploitable, no false positive |
| 85-94 | High probability issue, needs minor context to confirm |
| 80-84 | Possible issue, needs manual review |
| < 80 | Likely false positive, auto-filtered |

## Notes / 注意事项

- Never modify user code, output report only
- For --diff mode, focus on newly introduced issues, don't report existing ones
- Web projects: extra check CSP, CORS, HTTPS config
- Electron/desktop apps: extra attention to main/preload/renderer security boundary
- CLI projects: check argument parsing, error exit codes, pipe safety
- Large projects (>100 files): default to smart scan, prompt about `--full` for full audit
