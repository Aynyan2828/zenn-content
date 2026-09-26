#!/bin/bash
# 使い方: npm run new -- <slug>
# slug は a-z0-9 と - _ の 12〜50 文字（Zenn の決まり）
set -euo pipefail
cd "$(dirname "$0")/.."
slug="${1:-}"
if [[ ! "$slug" =~ ^[a-z0-9_-]{12,50}$ ]]; then
  echo "[new_draft] slug は a-z0-9-_ の 12〜50 文字にしてください: '$slug'" >&2
  exit 1
fi
dst="articles/${slug}.md"
if [[ -e "$dst" ]]; then
  echo "[new_draft] もうあります: $dst（上書きしません）" >&2
  exit 1
fi
cp templates/article_template.md "$dst"
echo "[new_draft] 下書きを作りました: $dst（published: false）"
echo "[new_draft] 見た目の確認: npm run preview → http://localhost:8000"
