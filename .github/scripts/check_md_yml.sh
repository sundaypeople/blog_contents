#!/bin/bash
set -euo pipefail

fail=0

# posts ディレクトリ以下の全ての .md ファイルをチェック
while IFS= read -r -d '' file; do
  echo "Checking $file"

  # ファイルの先頭行が '---' で始まっているか確認
  if ! head -n 1 "$file" | grep -q '^---'; then
    echo "ERROR: $file does not start with YAML frontmatter (missing ---)"
    fail=1
    continue
  fi

  # YAMLフロントマター部分を抽出（最初の '---' と次の '---' の間）
  frontmatter=$(awk 'BEGIN {inBlock=0}
    /^---/ {if (inBlock==0) {inBlock=1; next} else {exit}}
    {if (inBlock==1) print}' "$file")

  if [ -z "$frontmatter" ]; then
    echo "ERROR: $file: YAML frontmatter is empty or not properly closed"
    fail=1
    continue
  fi

  # 必須キー "title:" と "tags:" の存在かつフォーマット（コロンの後に半角スペースが必要）をチェック
  if ! echo "$frontmatter" | grep -E -q '^[[:space:]]*title:[[:space:]]+'; then
    echo "ERROR: $file: 'title' key is missing or not properly formatted (must have a space after colon)"
    fail=1
  fi
  if ! echo "$frontmatter" | grep -E -q '^[[:space:]]*tags:[[:space:]]+'; then
    echo "ERROR: $file: 'tags' key is missing or not properly formatted (must have a space after colon)"
    fail=1
  fi
done < <(find posts -type f -name "*.md" -print0)

if [ "$fail" -eq 1 ]; then
  echo "One or more Markdown files in posts have invalid YAML frontmatter."
  exit 1
fi

echo "All Markdown files in posts have valid YAML frontmatter."
