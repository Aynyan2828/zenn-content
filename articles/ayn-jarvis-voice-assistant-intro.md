---
title: "Claude Code を手足にした自宅の JARVIS「AYN Jarvis」を10日で作った（iPhone・Obsidian連携）"
emoji: "⚙️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["claudecode", "python", "swiftui", "obsidian", "voicevox"]
published: false
---

はじめまして、あゆにゃんです。元・二等機関士（船のエンジン担当）で、今は焼却炉の運転員をしながら個人開発をしています。

最初の記事なので、自己紹介を兼ねて、いちばん毎日使っている自作ツール **AYN Jarvis** を紹介します。映画『アイアンマン』の JARVIS のように、Mac mini に常駐していて、話しかけると返事をし、そのまま作業までこなす音声アシスタントです。名前の AYN は、一緒に開発している「機関士AI」のキャラクターです。

![AYN（水彩のキャラクター）](/images/ayn-jarvis/rig.png =360x)
*AYN。HUD の中では、髪の揺れ・まばたき・口パクで動きます*

## 課題

個人開発をしていると、細かい用事が一日中続きます。

- Claude Code のセッションが許可待ちで止まっていないか見に行く
- 照明・音楽・予定・天気などを、それぞれ別のアプリで確認する
- 家にいる間の「ちょっとこれやって」を、いちいちキーボードで打つのが面倒

外出先や仕事中に思いついた開発ネタは、スマホの Claude（Dispatch）でその場でプロンプトにして Obsidian の Vault に保存し、家に帰ってから Claude Code に実行させる流れがすでにできていました（後述）。残っていたのは **家で机に向かっているときの細かい用事** です。「手を止めずに声で頼めて、実作業は Claude Code がやってくれる」形にしたい、というのが出発点です。

## 作ったもの

![AYN Jarvis の全体像：入口（Mac の PTT・iPhone・Siri・Discord）→ whisper.cpp → Claude Code（読むだけは自動、書く・送るは Jev が判断して声で確認）→ VOICEVOX と HUD。人格や伝言板は Obsidian Vault から](/images/ayn-jarvis/cards/d_arch.png)

同じ「脳」に、Mac のマイク・iPhone アプリ・Siri・Discord の4か所から話しかけられます。

![入口と経路：Mac は PTT、iPhone は Bridge アプリから Tailscale 経由、Siri は App Intent、Discord はボットから MCP ツール](/images/ayn-jarvis/cards/t_entry.png)

![規模：開発10日・198コミット・Python 13,469行・テスト262本・Claude Code の出力トークン約381万・キャッシュ書き込み約2,766万・キャッシュ読み込み約21.5億](/images/ayn-jarvis/cards/t_scale.png)

トークン数は、Claude Code のセッションログ（`~/.claude/projects/` の jsonl）から、ayn-jarvis のファイルを5回以上編集したセッション21本の `usage` を合計したものです。同じセッション内で別の作業をした分も含むので、目安として見てください。サブスク（定額）の範囲内で使っているので、トークン単位の追加請求はありません。量の大半はキャッシュ読み込みで、長い会話で同じ文脈を読み直し続けた分です。

![HUD](/images/ayn-jarvis/hud_present.webp)
*HUD の全画面モード。左に CPU/メモリ/接続状態、右にサブスク枠・今日の予定・Claude Code のセッション一覧・直近のツール実行。背景は Three.js の粒子*

## なぜ「押している間だけ聞く（PTT）」にしたか

起動の方式は3つ試したり検討したりして、最終的に PTT（Push To Talk）に落ち着きました。

![起動方式の比較：ダブルクラップは誤反応が多く不採用、ウェイクワード常時待ち受けは雑音と幻聴、PTT を2日目に既定に](/images/ayn-jarvis/cards/t_ptt.png)

ウェイクワード方式では、実際に次のようなことが起きていました。

![ウェイクワード方式で困ったこと：whisper の幻聴、聞き間違い、言いかけの分断](/images/ayn-jarvis/cards/t_wake.png)

PTT にすると、**押していない間はそもそも録音しない** ので、雑音対策の大半が不要になります。F12 は macOS 全体で拾っているので、どのアプリを使っていても話しかけられます。ウェイクワード方式も設定1つで戻せるように残してあります。

## できること

特に便利なのが **伝言板** です。AYN と話している途中で、その場ではできないことや腰を据えてやるべき作業が出てきたら、「それ伝言板に残しといて」と頼むだけ。会話の中身を一言に要約して Vault に追記し、次に Claude Code のセッションを開くと自動で読み込まれて片付きます（仕組みは後述）。

![Claude Code との連携：伝言板・セッションの見張り・サブスク枠・Codex への依頼](/images/ayn-jarvis/cards/t_cc.png)

![暮らしの用事：朝の点呼・予定と天気・照明・音楽・週次ダイジェスト](/images/ayn-jarvis/cards/t_life.png)

![Mac の操作：開く・OS の状態・アプリ操作・画面を見る・要約・ディクテーション・部品を名前で押す](/images/ayn-jarvis/cards/t_mac.png)

![覚える・選ぶ：言い回しの学習・番号で選ぶ・会話の持ち越し](/images/ayn-jarvis/cards/t_memory.png)

![作る・出す：出力の切り替え・日報と機関日誌・トレンド調査から動画・Discord の画像](/images/ayn-jarvis/cards/t_make.png)

![見た目：表示の切り替え・パジャマ・表情・3D Brain などの画面](/images/ayn-jarvis/cards/t_look.png)

![表情6種](/images/ayn-jarvis/expressions.png)
*表情は Live2D を使わず、カスタム GPT に「一点だけ変えた絵」を描かせて差分からパーツを切り出し、自前のリグで動かしています（待機・髪が揺れる・にっこり＋首かしげ・ウインク・驚き・照れ）*

![Actions](/images/ayn-jarvis/act.png)
*Actions 画面。レポート生成・照明・点呼・Inbox 精査・Vault 検索・日報・Mac 操作などをボタンで頼めます*

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

最後から2つ目の分岐では、**「確認するかどうか」の判断そのものを、最近話題の判断専用モデル Jev に任せています**。聞くのは「破壊的か／頼まれた範囲内か／秘密に触るか」の3問だけで、全部「安全」と高確信なら確認を省きます。毎回「してよかですか？」と聞かれ続けるとつい適当に「よかよ」と答えてしまうので、本当に聞くべきときだけ聞く、が狙いです。ただし `rm -rf`・`git push`・送信系・メール送信は、モデルが安全と言っても必ず確認します。![Jev 判断層の全体図](/images/ayn-jarvis/jev_arch.png)
*判断だけを Jev に任せ、文章の生成と実行は今までどおり Claude Code が行う*

![実際の判定ログ](/images/ayn-jarvis/jev_log.png)
*実際の判定ログ（抜粋）。3つの確率から allow / confirm / deny を決める。`rm -rf` は deny*

この判断層（クラウドの Jev とローカルの Kev の使い分け）は、データがもう少し溜まったら別の記事で数字付きで書く予定です。

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

![iPhone の Bridge アプリ](/images/ayn-jarvis/iphone_bridge.webp)
*iPhone の Bridge アプリ。左から AYN タブ（マイク長押しか文字で話しかける）、操縦席（サイトと YouTube の数字）、3D Brain、Dashboard。Mac の画面を Tailscale 越しにそのまま開いています*

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

![Obsidian 連携：外出先のアイデアを Dispatch でプロンプト化して Vault へ・終わったら AI が Done へ移す・人格ノート・伝言板・リマインダー同期・3D Brain](/images/ayn-jarvis/cards/t_obsidian.png)

伝言板はファイル1枚で、未読と既読の2段だけ。既読は7日で月別のログに移すので膨らみません。3D Brain では、macOS が返す日本語ファイル名（NFD）を NFC にそろえてからリンクを解決しています。ここを揃えないと、濁点の付いたノートへのリンクがすべて「切れている」扱いになります。

![3D Brain](/images/ayn-jarvis/brain.png)
*3D Brain。ログ類を除いた1,289ノートと1,772本のリンクを、フォルダ（カテゴリ）ごとに色分けして表示。粒1つが1ノートで、押すとそのノートの要約が横に出ます。「成長を再生」を押すと、ひとつのメモから脳が育っていく様子を再生します*

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

![使える所：即答コマンド・危ない操作だけ聞くゲート・Obsidian で文脈共有。まだ無理：ローカルの小さなモデルだけでは危険判定が甘い・macOS の許可は手作業](/images/ayn-jarvis/cards/t_limits.png)

## 学び

![学び：判定は1か所に集める・決まった用事は LLM に渡さない・文脈はツールの外（Obsidian）に置く](/images/ayn-jarvis/cards/t_lessons.png)

コードは今のところ非公開ですが、この記事の範囲で質問があればコメントでどうぞ。

---

*元・二等機関士、今は焼却炉運転員。機関士AI「AYN」と個人開発しとります。*
