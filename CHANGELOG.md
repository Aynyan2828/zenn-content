# CHANGELOG

## 2026-09-27 — 初期セットアップ（Prompt253 P1）

- zenn-cli を導入（`npx zenn init`）
- 記事テンプレ `templates/article_template.md`・下書き作成 `npm run new`
- 公開ストッパー `.githooks/pre-push`（`published: true` の記事があると一覧を出して y 待ち・端末が無ければ止める）
