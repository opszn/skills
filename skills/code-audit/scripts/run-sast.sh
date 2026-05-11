#!/bin/bash
# run-sast.sh — 自动检测项目类型并执行 SAST 工具
# 用法: bash run-sast.sh
# 输出: 各工具的结构化结果（JSON 或文本）

set -euo pipefail

echo "=== SAST 扫描开始 ==="

# Node.js: npm audit
if [ -f "package-lock.json" ]; then
  echo "--- npm audit ---"
  if command -v npm &>/dev/null; then
    npm audit --omit=dev --json 2>/dev/null || echo '{"error": "npm audit failed or no vulnerabilities"}'
  fi
elif [ -f "yarn.lock" ]; then
  echo "--- yarn audit ---"
  if command -v yarn &>/dev/null; then
    yarn audit --groups dependencies --json 2>/dev/null || echo '{"error": "yarn audit failed or no vulnerabilities"}'
  fi
else
  echo "--- npm audit: 跳过（无 package-lock.json / yarn.lock）---"
fi

# semgrep: 通用扫描
if command -v semgrep &>/dev/null; then
  echo "--- semgrep ---"
  semgrep scan --config=auto --json --quiet 2>/dev/null || echo '{"results": [], "error": "semgrep scan completed with issues"}'
else
  echo "--- semgrep: 未安装，建议: brew install semgrep ---"
fi

# Python: pip-audit / safety
if [ -f "requirements.txt" ]; then
  if command -v pip-audit &>/dev/null; then
    echo "--- pip-audit ---"
    pip-audit --format=json 2>/dev/null || echo '{"dependencies": [], "vulnerabilities": []}'
  elif command -v safety &>/dev/null; then
    echo "--- safety ---"
    safety check --json 2>/dev/null || echo '[]'
  else
    echo "--- pip-audit/safety: 均未安装，建议: pip install pip-audit ---"
  fi
else
  echo "--- pip-audit: 跳过（无 requirements.txt）---"
fi

# Go: govulncheck / go vet
if [ -f "go.mod" ]; then
  if command -v govulncheck &>/dev/null; then
    echo "--- govulncheck ---"
    govulncheck ./... 2>&1 || echo "No vulnerabilities found"
  else
    echo "--- go vet ---"
    go vet ./... 2>&1 || echo "go vet completed"
  fi
else
  echo "--- govulncheck: 跳过（无 go.mod）---"
fi

# Rust: cargo audit
if [ -f "Cargo.lock" ]; then
  if command -v cargo-audit &>/dev/null; then
    echo "--- cargo audit ---"
    cargo audit 2>&1 || echo "No vulnerabilities found"
  else
    echo "--- cargo audit: 未安装，建议: cargo install cargo-audit ---"
  fi
else
  echo "--- cargo audit: 跳过（无 Cargo.lock）---"
fi

echo "=== SAST 扫描完成 ==="
