---
title: "Claude Code を“手足”にした自宅の音声アシスタントを10日で作った（Mac常駐・iPhone・Obsidian連携）"
emoji: "⚙️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["claudecode", "python", "swiftui", "obsidian", "voicevox"]
published: false
---

はじめまして、あゆにゃんです。元・二等機関士（船のエンジン担当）で、今は焼却炉の運転員をしながら個人開発をしています。

最初の記事なので、自己紹介を兼ねて、いちばん毎日使っている自作ツール **AYN Jarvis** を紹介します。Mac mini に常駐していて、話しかけると AI が返事をし、そのまま作業までこなす音声アシスタントです。名前の AYN は、一緒に開発している「機関士AI」のキャラクターです。

## 課題

個人開発をしていると、細かい用事が一日中続きます。

- Claude Code のセッションが許可待ちで止まっていないか見に行く
- 照明・音楽・予定・天気などを、それぞれ別のアプリで確認する
- 家にいる間の「ちょっとこれやって」を、いちいちキーボードで打つのが面倒

外出先や仕事中に思いついた開発ネタは、スマホの Claude（Dispatch）でその場でプロンプトにして Obsidian の Vault に保存し、家に帰ってから Claude Code に実行させる流れがすでにできていました（後述）。残っていたのは **家で机に向かっているときの細かい用事** です。「手を止めずに声で頼めて、実作業は Claude Code がやってくれる」形にしたい、というのが出発点です。

## 作ったもの

```
🎤 マイク（PTT：押している間だけ聞く）
 └→ whisper.cpp（whisper-server 常駐・large-v3-turbo・日本語）
     └→ Claude Agent SDK ＝ Claude Code（脳）
          ├ 読み取り系ツール：自動で許可
          ├ 書き込み・送信系：「してよかですか？」と声で確認
          └ 人格：Obsidian Vault のキャラ設定ノート
              └→ VOICEVOX（声） → スピーカー
                 └→ HUD（常に最前面の小窓。字幕・口パク・状態表示）
```

同じ「脳」に、Mac のマイク・iPhone アプリ・Siri・Discord の4か所から話しかけられます。

| 入口 | 経路 |
|---|---|
| Mac | PTT（F12 か右 Option を押している間だけ録音） |
| iPhone | 自作アプリ Bridge の AYN タブ → Tailscale 経由の HTTP |
| Siri | 「あゆにゃんに」→ App Intent → 同じ API |
| Discord | 自作ボット → MCP ツール → 同じ API |

規模（2026-09-27 時点）：

| 項目 | 値 |
|---|---|
| 開発期間 | 2026-09-17〜（10日） |
| コミット | 198 |
| Python（src 配下） | 13,469 行 |
| テスト | 262 本（すべて pass） |

<!-- 画像: HUD 全画面のスクショ（あとで差し込む） -->

## なぜ「押している間だけ聞く（PTT）」にしたか

起動の方式は3つ試したり検討したりして、最終的に PTT（Push To Talk）に落ち着きました。

| 方式 | 結果 |
|---|---|
| ダブルクラップ（手を2回叩いて起動） | 物音や生活音で誤反応が多すぎるので採用しませんでした |
| ウェイクワード常時待ち受け（「あゆにゃん」で起きる） | 最初はこれで作りました。ただ、ずっとマイクを開けているので雑音を拾い続けます |
| **PTT（F12 か右 Option を押している間だけ）** | **2日目の v0.4.0 で既定にしました** |

ウェイクワード方式で実際に困ったこと：

- **whisper の“幻聴”**：環境音しかないのに、whisper がヒント用に渡していた例文（「マスター、今日の予定ば教えて。」）を、約4秒おきに文字起こし結果として吐き出していました。放置すると、存在しない「あゆにゃん、こんにちは」で勝手に起きかねません
- **聞き間違い**：「あゆにゃん」の誤認識パターンを11個登録しても、取りこぼしと誤起動が残りました
- **言いかけの分断**：「えっと、Live2D作る。」「作りたいんだよ。」のように間が空くと、続きが別の命令として割り込み、前の処理がエラー終了していました

PTT にすると、**押していない間はそもそも録音しない** ので、雑音対策の大半が不要になります。F12 は macOS 全体で拾っているので、どのアプリを使っていても話しかけられます。ウェイクワード方式も設定1つで戻せるように残してあります。

## できること

よく使うものだけ挙げます。

- **朝の点呼**：7:30 に天気 → 今日の予定 → Claude Code の許可待ち → 伝言の未読 → 照明 → サブスクの使用枠を、約30秒の一続きの台詞で読み上げます。決まった内容なので LLM を通さず、その場で組み立てます
- **Claude Code の見張り**：`~/.claude/sessions/` を15秒おきに読み、45秒以上許可待ちで止まっているセッションがあれば「◯◯が止まっとるよ」と声で知らせます
- **Mac 操作**：アプリやファイルを開く、音楽の再生・停止、メールの下書き、カレンダーやメモへの追記、許可リストに入れたショートカットの実行
- **画面を見る**：「このエラー何？」でスクショを撮り、Claude Code に画像として読ませます
- **家の照明**：Raspberry Pi の赤外線リモコンに HTTP で指示します。取り消せる操作なので確認は省いています
- **出力の切り替え**：「HTMLで出して」「グラフにして」「PDFにして」「スマホに送って」。1つの結果を、フォーマッタを差し替えて出し分けます

## 実装1：確認ゲート ― 危ない操作だけ声で聞く

これがいちばんの肝です。Claude Agent SDK の `can_use_tool` に、自前のゲートを1か所だけ挟んでいます。

```python
options = ClaudeAgentOptions(
    permission_mode="default",
    # 書き込み・送信系は allowed_tools に入れない = 必ず can_use_tool を通る
    allowed_tools=sorted(self.auto_allow - UNSAFE_AUTO_ALLOW),
    disallowed_tools=sorted(self.never_allow),
    can_use_tool=self._gate,
    # ~/.claude の settings / CLAUDE.md / フック / メモリを一切読まない
    setting_sources=[],
    # 画像を Read すると1メッセージが数MBになる。既定の1MBだと脳ごと落ちた
    max_buffer_size=16 * 1024 * 1024,
)
```

`setting_sources=[]` は大事です。これを入れないと、普段の Claude Code 用に仕込んである SessionStart フックの業務連絡（「git に未コミットがあります」など）が、音声の返事に混ざって読み上げられます。

ゲート本体は「読むだけなら通す／秘密の場所は拒否／それ以外は声で確認」の順に判定します（抜粋）。

```python
async def _gate(self, tool_name, inp, ctx):
    if tool_name in self.never_allow:
        return PermissionResultDeny(message="音声からは使えん設定", interrupt=False)
    if tool_name == "Read":
        p = str(resolve(inp.get("file_path", "")))
        if any(fnmatch(p, g) for g in self.read_deny):      # 鍵・.env など
            return PermissionResultDeny(message="秘密の場所は読めん", interrupt=False)
        if any(fnmatch(p, g) for g in self.read_allow):     # プロジェクト・Vault
            return PermissionResultAllow()
    if tool_name == "Bash" and is_readonly_bash(inp.get("command", "")):
        return PermissionResultAllow()
    # 判断モデルが「安全」と高確信のときだけ確認を省略。曖昧・不達なら確認に倒す
    if await self._jev_allows(tool_name, inp):
        return PermissionResultAllow()
    return await self._confirm_or_deny(describe_tool(tool_name, inp))
```

確認の返事が聞き取れなかったときは **却下** として扱います。迷ったら止める（fail-closed）という方針です。

最後から2つ目の分岐では、判断専用の小さなモデルに「破壊的か／頼まれた範囲内か／秘密に触るか」の3問だけを聞き、全部「安全」と高確信なら確認を省いています。ただし `rm -rf`・`git push`・送信系・メール送信は、モデルが安全と言っても必ず確認します。この判断層（クラウドの Jev とローカルの Kev の使い分け）は、データがもう少し溜まったら別の記事で数字付きで書く予定です。

## 実装2：Mac 操作は「判定を1か所」に

Mac 操作は、何を自動でやって何を聞くかを `classify` 1か所に集めました。声の即答コマンドと脳のツールの両方が、この判定を使います。

```python
def classify(self, action, arg=""):
    """(decision, 理由)。decision は auto / confirm / jev / deny"""
    if action == "open":
        kind = self._target_kind(arg)
        if kind in ("web", "app"):
            return "auto", "ウェブ/アプリを開くだけ"
        if kind == "url":
            return "confirm", "http(s) 以外の URL は何が起きるか読めん"
        p = resolve(arg)
        if self._path_denied(p):
            return "deny", "秘密の場所・鍵のファイルは開かん"
        if self._needs_confirm_ext(p):          # .command / .app / .sh …
            return "confirm", "開くと何かが動く"
        return "auto", "普通のファイル/フォルダを開くだけ"
    if action == "mail_draft":
        return "auto", "下書きの窓を出すだけ（送らん）"
    if action == "mail_send":
        return "confirm", "メールは送ったら取り消せん"
    if action in ("calendar_add", "notes_append"):
        return "jev", "書き足すだけ（消しはせん）"
    ...
```

AppleScript には **値をすべて argv で渡し**、スクリプトの中に文字列を埋め込みません。引用符をはさんだ注入を防ぐためです。

スクリプトから操作できないアプリは、最後の手段として **アクセシビリティ（AX）の部品名** でボタンを押します。ピクセル座標ではないので、窓の位置が変わっても動きます。パスワード欄には書き込まず、「送信」「購入」「削除」「ログイン」などを含む部品とダイアログの中では、毎回確認します。

## 実装3：iPhone と Siri から同じ脳へ

Mac 側は `POST /api/ask` を1本だけ用意しています。

```
POST /api/ask {text, source, audio, image?}
 → {status: "done",    reply, audio_url, expression}
 → {status: "confirm", question, job}   … 確認待ち（POST /api/confirm で返事）
 → {status: "running", job}             … 長い作業（GET /api/job/{id} で追う）
```

- 認証はヘッダのトークンで、サーバーはローカルと Tailscale の IP にだけ bind しています
- Mac の声・iPhone・Discord は1つのロックで直列にし、同じ会話セッションを共有します。iPhone で頼んだ続きを Mac で話せます
- iPhone アプリ（SwiftUI）は返事を VOICEVOX の声で再生し、アプリ内の AYN が口パクします

Siri からは App Intent を1つ作っただけです。ショートカット App で「あゆにゃんに」という名前のショートカットにこのアクションを入れると、「Hey Siri、あゆにゃんに」で話しかけられます。

```swift
struct AskAynIntent: AppIntent {
    static var title: LocalizedStringResource = "AYN に聞く"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "言葉", requestValueDialog: "AYN に何て言う？")
    var text: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        // 直前が確認待ちで、今回が「よかよ / やめて」なら /api/confirm へ
        // （Siri 経由の requestConfirmation は落ちるので使わない）
        ...
    }
}
```

はまった点：**Siri の `requestConfirmation` はこの用途だと落ちました**。そこで、確認待ちの job ID を `UserDefaults` に残しておき、次に「あゆにゃんに → よかよ」と呼ばれたら `/api/confirm` に流す方式にしました。

## 実装4：Obsidian Vault を“記憶と文脈”にする

AYN Jarvis の文脈は、すべて Obsidian の Vault（約7,000ノート）に置いています。どの AI ツールから始めても、同じ前提から話が始まるようにするためです。

- **外出先のアイデア → プロンプト → Claude Code**：仕事中や外出先で思いついたことは、スマホの Claude（Dispatch）で `PromptNNN_タイトル_日付.md` という1枚のプロンプトにして、Vault の `00_Inbox/Prompts/` に保存します。家では Claude Code に「プロンプト253やって」と言うだけで、目的・制約・フェーズ・テスト手順がそろった状態から作業が始まります。終わったら実行した AI 自身が frontmatter を `status: done` にして `Done/年-月/` へ移すので、Inbox には未着手のものだけが残ります（これまでに Done が195本）。AYN Jarvis 自体も、このプロンプトの積み重ねで作りました
- **人格**：キャラクター設定ノートを正本にし、口調に効く見出しだけを抜き出してシステムプロンプトにしています。ノートを直せば、次の会話から AYN の話し方が変わります
- **伝言板（声 → Claude Code）**：「Claude Code に伝えて、◯◯」と言うと、AYN が一言に要約して Vault の `AYN_Jarvis_Inbox.md` に1行足します。Claude Code 側は SessionStart フックで未読だけを読み込み、片付けたら `[x]` を付けます。ファイルは1枚で、未読と既読の2段だけ。既読は7日で月別のログに移すので、ファイルが膨らみません
- **iPhone のリマインダーと同期**：伝言板の未読をリマインダー.app に入れ、既読になったらチェックを付けます。逆に、iPhone でチェックすれば伝言板も既読になります（30秒ごとにファイルの状態と照らし合わせ）
- **3D Brain**：Vault のリンク構造を 3D グラフにして、HUD に表示します。リンクの解決は Obsidian と同じくファイル名の一致で行い、macOS が返す日本語ファイル名（NFD）は NFC にそろえてから比べています。ここを揃えないと、濁点の付いたノートへのリンクがすべて「切れている」扱いになります
- **レポートの保存**：「Vault に保存して」で、frontmatter 付きの Markdown として残します

<!-- 画像: 3D Brain のスクショ（あとで差し込む） -->

## 参考にしたリポジトリ

ゼロから考えたものはほとんどなく、先人の音声アシスタントや UI からアイデアを借りています。コードを直接使ったものと、発想だけ借りたものを分けて書きます（発想だけのものは、読んだうえで Python に書き直しています）。

### 発想を借りたもの

- **ethanplusai/jarvis** ― Claude Code 用の音声アシスタント。脳の入れ替え中に HUD を暗くする演出、サブスク使用枠のゲージ、Claude Code セッションの見張り
  https://github.com/ethanplusai/jarvis
- **isair/jarvis** ― ローカル完結の音声アシスタント。キーを押している間に話した言葉を前面のアプリに貼るディクテーション、「画面見て」
  https://github.com/isair/jarvis
- **Open-LLM-VTuber** / **airi** ― アバターをクリックしたときの反応、マウスの方へ首をかしげる視線追従
  https://github.com/Open-LLM-VTuber/Open-LLM-VTuber
  https://github.com/moeru-ai/airi
- **JARVIS（Electron 版・Akshat Singh 氏ほか・MIT）** ― OS 操作の範囲、言い回しを覚える仕組み、番号付きの候補から選ぶ操作、コンソール窓の画面設計
- **Arwes** / **augmented-ui** ― 全画面 HUD の、角を落とした枠のパネルの意匠
  https://github.com/arwes/arwes
  https://github.com/propjockey/augmented-ui

### 仕組みごと使わせてもらったもの

- **nateherkai/AIS-OS** ― 3D Brain の描画側をほぼそのまま使い、Vault を読むグラフ生成は日本語向けに Python で書き直しました
  https://github.com/nateherkai/AIS-OS
- **jaredpalmer/kev** ― ローカルで動く判断モデル（確認ゲートと AX 操作の「次どれ押す」で使用）
  https://github.com/jaredpalmer/kev
- **Claude Agent SDK（Python）** ― 脳
  https://github.com/anthropics/claude-agent-sdk-python
- **whisper.cpp** ― 音声認識
  https://github.com/ggml-org/whisper.cpp
- **VOICEVOX** ― 声（ナースロボ＿タイプＴ）
  https://github.com/VOICEVOX/voicevox_engine
- **three.js** ― HUD 背景の 3D
  https://github.com/mrdoob/three.js

どれも公開してくださっている方々のおかげです。ありがとうございます。

## 使える所・まだ無理な所

- **使える**
  - 朝の点呼・照明・音楽・予定の確認のような決まった用事は、LLM を通さない即答コマンドにしたので速く、毎日使えています
  - 「危ない操作だけ声で聞く」ゲートのおかげで、Claude Code に Bash を渡したままでも安心して使えます
  - Obsidian を正本にしているので、別の AI ツール（Claude Code・Codex など）とも同じ文脈を共有できます
- **まだ無理**
  - 確認を省く判断は、ローカルの小さなモデルだけだと「危ない／安全」を見分けきれませんでした。今はクラウドの判断モデルを主にしています（詳しくは次の記事で）
  - macOS の許可（画面収録・アクセシビリティ・オートメーション）は、どうしても手作業での付与が必要です。launchd から起動した Python には許可が付かないので、Swift 製の HUD アプリ側に寄せています

## 学び

- **判定は1か所に集める**。声・iPhone・Discord と入口が増えても、安全の判断がぶれません
- **決まった用事は LLM に渡さない**。速くて、安くて、毎日同じ結果になります
- **文脈はツールの外（Obsidian）に置く**。AI ツールを乗り換えても、積み上げたものが残ります

コードは今のところ非公開ですが、この記事の範囲で質問があればコメントでどうぞ。

---

*元・二等機関士、今は焼却炉運転員。機関士AI「AYN」と個人開発しとります。*
