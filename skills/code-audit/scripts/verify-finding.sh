#!/bin/bash
# verify-finding.sh — 验证特定 CWE 类型的问题是否已修复
# 用法: bash verify-finding.sh <CWE> <file>
# 示例: bash verify-finding.sh CWE-22 main.js
# 输出: JSON {"cwe": "CWE-22", "file": "main.js", "status": "FIXED|FAILING|MODIFIED", "details": "..."}

set -euo pipefail

CWE="${1:-}"
FILE="${2:-}"

if [ -z "$CWE" ] || [ -z "$FILE" ]; then
  echo '{"error": "用法: verify-finding.sh <CWE> <file>"}'
  exit 1
fi

if [ ! -f "$FILE" ]; then
  echo "{\"cwe\": \"$CWE\", \"file\": \"$FILE\", \"status\": \"FAILING\", \"details\": \"文件不存在: $FILE\"}"
  exit 0
fi

verify() {
  local cwe="$1"
  local file="$2"

  case "$cwe" in
    CWE-22|cwe-22)
      # 路径遍历 — 检查是否有 path.resolve + startsWith 校验
      if grep -q 'path\.resolve\|path\.realpath' "$file" 2>/dev/null && \
         grep -q 'startsWith\|indexOf\|match.*path' "$file" 2>/dev/null; then
        echo "FIXED|已添加路径校验逻辑"
      elif grep -q 'path\.resolve\|path\.realpath' "$file" 2>/dev/null; then
        echo "MODIFIED|仅有 path.resolve，缺少 startsWith 校验，需人工复核"
      else
        echo "FAILING|未发现路径校验逻辑"
      fi
      ;;

    CWE-79|cwe-79)
      # XSS — 检查 innerHTML / dangerouslySetInnerHTML 是否仍有直接赋值
      if grep -q 'innerHTML\|dangerouslySetInnerHTML\|outerHTML\|insertAdjacentHTML\|document\.write' "$file" 2>/dev/null; then
        if grep -q 'sanitize\|escape\|purify\|DOMPurify' "$file" 2>/dev/null; then
          echo "MODIFIED|存在 DOM 操作但有 sanitize，需人工复核"
        else
          echo "FAILING|仍存在直接的 HTML 赋值"
        fi
      else
        echo "FIXED|无直接 HTML 赋值"
      fi
      ;;

    CWE-78|cwe-78)
      # 命令注入 — 检查 exec/execSync 是否使用字符串拼接
      if grep -q 'exec\|execSync\|spawnSync' "$file" 2>/dev/null; then
        if grep -q '\.exec.*+.*\|execSync.*+\|exec.*\`' "$file" 2>/dev/null; then
          echo "FAILING|exec 仍存在字符串拼接"
        else
          echo "MODIFIED|存在 exec 调用但无拼接，需人工复核"
        fi
      else
        echo "FIXED|无 exec 调用"
      fi
      ;;

    CWE-89|cwe-89)
      # SQL 注入 — 检查 query/execute 是否使用拼接
      if grep -q '\.query\|\.execute\|\.exec' "$file" 2>/dev/null; then
        if grep -q '\.query.*+.*\|\.execute.*+.*\|Query.*Sprintf\|Exec.*Sprintf' "$file" 2>/dev/null; then
          echo "FAILING|SQL 查询仍存在字符串拼接"
        else
          echo "MODIFIED|存在 SQL 查询但无拼接，需确认参数化"
        fi
      else
        echo "FIXED|无 SQL 查询"
      fi
      ;;

    CWE-798|cwe-798)
      # 硬编码密钥 — 检查是否仍有硬编码
      if grep -q 'password\s*=\s*["\x27][^"\x27]\{3,\}\|secret\s*=\s*["\x27][^"\x27]\{3,\}\|api_key\s*=\s*["\x27][A-Za-z0-9]\{10,\}' "$file" 2>/dev/null; then
        echo "FAILING|仍存在硬编码密钥"
      else
        echo "FIXED|无硬编码密钥"
      fi
      ;;

    CWE-391|cwe-391)
      # 空 catch — 检查是否仍有空 catch
      if grep -q 'catch.*{.*}' "$file" 2>/dev/null; then
        echo "FAILING|仍存在空 catch"
      else
        echo "FIXED|无空 catch"
      fi
      ;;

    *)
      echo "MODIFIED|未知 CWE 类型 $cwe，使用 grep 验证原始模式"
      ;;
  esac
}

RESULT=$(verify "$CWE" "$FILE")
STATUS="${RESULT%%|*}"
DETAILS="${RESULT#*|}"

echo "{\"cwe\": \"$CWE\", \"file\": \"$FILE\", \"status\": \"$STATUS\", \"details\": \"$DETAILS\"}"
