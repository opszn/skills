#!/bin/bash
# write-draft.sh — 管理写作草稿版本
# 用法: bash write-draft.sh new|save|list|diff [version]

set -euo pipefail

DRAFTS_DIR="writing-drafts"
ACTION="${1:-help}"
VERSION="${2:-}"

mkdir -p "$DRAFTS_DIR"

case "$ACTION" in
  new)
    # 创建新草稿文件
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    FILE="$DRAFTS_DIR/draft-$TIMESTAMP-v1.md"
    echo "# 草稿" > "$FILE"
    echo "" >> "$FILE"
    echo "创建新草稿: $FILE"
    echo "$FILE"
    ;;

  save)
    # 保存新版本
    # 找到最新版本号，递增
    LATEST=$(ls "$DRAFTS_DIR"/draft-*.md 2>/dev/null | sort | tail -1)
    if [ -n "$LATEST" ]; then
      # 提取版本号
      BASE=$(basename "$LATEST")
      VER=$(echo "$BASE" | grep -o 'v[0-9]*\.md' | grep -o '[0-9]*')
      NEXT=$((VER + 1))
      PREFIX=$(echo "$BASE" | sed "s/v[0-9]*\.md//")
      NEW_FILE="$DRAFTS_DIR/${PREFIX}v${NEXT}.md"
    else
      TIMESTAMP=$(date +%Y%m%d-%H%M%S)
      NEW_FILE="$DRAFTS_DIR/draft-$TIMESTAMP-v1.md"
    fi
    echo "$NEW_FILE"
    ;;

  list)
    # 列出所有草稿
    if [ -d "$DRAFTS_DIR" ] && ls "$DRAFTS_DIR"/draft-*.md 1>/dev/null 2>&1; then
      echo "草稿列表:"
      ls -la "$DRAFTS_DIR"/draft-*.md
    else
      echo "暂无草稿"
    fi
    ;;

  diff)
    # 对比两个版本
    if [ -z "$VERSION" ]; then
      echo "用法: bash write-draft.sh diff <version2>"
      exit 1
    fi
    LATEST=$(ls "$DRAFTS_DIR"/draft-*.md 2>/dev/null | sort | tail -1)
    if [ -n "$LATEST" ]; then
      echo "对比最新版本与 $VERSION:"
      diff "$DRAFTS_DIR/$VERSION" "$LATEST" 2>/dev/null || echo "差异见上"
    else
      echo "暂无草稿"
    fi
    ;;

  help|*)
    echo "用法: bash write-draft.sh [new|save|list|diff] [version]"
    echo ""
    echo "  new   - 创建新草稿文件 (v1)"
    echo "  save  - 保存新版本 (自动递增版本号)"
    echo "  list  - 列出所有草稿"
    echo "  diff  - 对比最新版本与指定版本"
    ;;
esac
