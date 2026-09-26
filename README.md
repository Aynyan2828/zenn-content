# zenn-content

あゆにゃん（BCNOFNe）の Zenn 記事置き場。Zenn の GitHub 連携で、main に push した記事が反映されます。

## 決まり（Zenn のガイドラインを守るため）

- AI（Claude Code）が書くのは**下書きまで**（`published: false`）
- **マスターが全文を読んで直してから** `published: true` にする
- 自動で公開する仕組み（CI・cron・Hermes 経由）は作らない。目安は週1本まで
- 宣伝や外部への誘導を目的にしない。リンクは末尾に1つまで

## 使い方

```bash
npm install          # 初回だけ
npm run setup        # 初回だけ（公開ストッパーを有効にする）
npm run new -- jarvis-local-judgment-layer   # 下書きを作る
npm run preview      # http://localhost:8000 で見た目を確認
```

公開するとき：記事の `published: false` を `true` にして commit → `git push`。
push の前に「公開される記事の一覧」が出て、`y` を押したときだけ push されます（端末が無い自動実行では止まります）。

## 中身

- `articles/` 記事（1ファイル=1記事・ファイル名が slug）
- `books/` 本
- `images/` 記事の画像（`/images/xxx.png` で参照）
- `templates/article_template.md` 記事テンプレ（課題→作ったもの→実装→測った結果→使える所/まだ無理な所→学び）
- `.githooks/pre-push` 公開ストッパー
