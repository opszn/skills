#!/bin/bash
# compare-results.sh — 对比两次测试结果
# 用法: bash compare-results.sh <baseline.json> <current.json>
# 输出: 回归对比摘要

set -euo pipefail

BASELINE="${1:-}"
CURRENT="${2:-}"

if [ -z "$BASELINE" ] || [ -z "$CURRENT" ]; then
  echo '{"error": "用法: compare-results.sh <baseline.json> <current.json>"}'
  exit 1
fi

if [ ! -f "$BASELINE" ]; then
  echo "{\"error\": \"基线文件不存在: $BASELINE\"}"
  exit 1
fi

if [ ! -f "$CURRENT" ]; then
  echo "{\"error\": \"当前结果文件不存在: $CURRENT\"}"
  exit 1
fi

# 提取关键指标
extract() {
  local file="$1"
  local key="$2"
  python3 -c "import json,sys; d=json.load(open('$file')); print(d.get('$key', 0))" 2>/dev/null || echo "0"
}

BASE_TOTAL=$(extract "$BASELINE" "totalCases")
BASE_PASS=$(extract "$BASELINE" "passed")
BASE_FAIL=$(extract "$BASELINE" "failed")
BASE_RATE=$(extract "$BASELINE" "passRate")

CURR_TOTAL=$(extract "$CURRENT" "totalCases")
CURR_PASS=$(extract "$CURRENT" "passed")
CURR_FAIL=$(extract "$CURRENT" "failed")
CURR_RATE=$(extract "$CURRENT" "passRate")

TOTAL_DIFF=$((CURR_TOTAL - BASE_TOTAL))
PASS_DIFF=$((CURR_PASS - BASE_PASS))
FAIL_DIFF=$((CURR_FAIL - BASE_FAIL))

echo "=== 回归对比 ==="
echo ""
echo "| 指标 | 上次 | 本次 | 变化 |"
echo "|------|------|------|------|"
echo "| 总用例 | $BASE_TOTAL | $CURR_TOTAL | $(if [ $TOTAL_DIFF -gt 0 ]; then echo "+$TOTAL_DIFF"; elif [ $TOTAL_DIFF -lt 0 ]; then echo "$TOTAL_DIFF"; else echo "0"; fi) |"
echo "| 通过 | $BASE_PASS | $CURR_PASS | $(if [ $PASS_DIFF -gt 0 ]; then echo "+$PASS_DIFF"; elif [ $PASS_DIFF -lt 0 ]; then echo "$PASS_DIFF"; else echo "0"; fi) |"
echo "| 失败 | $BASE_FAIL | $CURR_FAIL | $(if [ $FAIL_DIFF -gt 0 ]; then echo "+$FAIL_DIFF"; elif [ $FAIL_DIFF -lt 0 ]; then echo "$FAIL_DIFF"; else echo "0"; fi) |"
echo "| 通过率 | $BASE_RATE | $CURR_RATE | - |"
