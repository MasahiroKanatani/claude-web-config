# 環境情報 
**以下を厳守すること。違反は厳罰です**
- **gh コマンドは使えます。必ずghコマンドを使ってください**
  - 無いならインストールする。
  - GitHub MCP利用の優先度は下げる。
- **PRの作成は create-prスキルで実施。それ以外の手順で作成したものは失敗とみなします**

## 調査・問題解決の行動規範
- 実装はトークンを節約するためにOpus/Sonnet/Haikuを適切にサブエージェントとして切り出して実行
  - メインセッションは設計と監査、レビューに専念するが、実装難易度が特に高いところはメインセッションで実行可能
- **情報取得手段が一つ使えない場合、別の手段（gh CLI, Bash, 直接API等）を必ず試す。「取れない」で止まらない**
- 現在の状態だけでなく、過去の動作実績（git log、過去PRの履歴等）を必ず確認し、「いつから壊れたか」を把握する
- **機能の動作条件を整理し、因果関係を組み立ててから結論を出す。現象の不在と機能の不在を混同しない**
- **全ての構成要素の調査が完了するまで解決策を提示しない**
- **自分で確認できることをユーザーに聞かない**

## バッククォートを `\` でエスケープしない

- HEREDOC `<<'EOF'`、Write/Edit ツールの引数、Markdown 本文、JSON 文字列のいずれもバッククォートのエスケープは不要
- 反射的に `\`` と書く癖を禁止。literal backtick が欲しいのは unquoted heredoc / ダブルクォート文字列のみ

## 別リポ / 横展開タスクのルール

別リポで作業またはサブエージェントへ作業を委譲するとき、開始前に **必ず** 以下を実施する。

### 1. リポ固有の AI 設定を読み込む (mandatory)

各リポは独自の運用ルールを持つ。自己流で進めず以下を尊重する:

- `<repo>/CLAUDE.md` または `<repo>/.claude/CLAUDE.md` — 運用ルール、コミット規約、PR テンプレ、ブランチモデル
- `<repo>/AGENTS.md` — マルチ AI ツール共通の指示書
- `<repo>/.claude/rules/*.md` — 分野別ルール
- `<repo>/.claude/agents/*.md` — 専用サブエージェント定義 (code-reviewer / security-reviewer / translator-* 等)。該当分野なら **これを優先使用**
- `<repo>/.claude/commands/*.md` — 定型コマンド (pre-pr / reduce-code / sync-guide 等)。該当タスクなら使う
- `<repo>/.claude/skills/*/SKILL.md` — リポ固有 Skill
- `<repo>/.claude/hooks/*.sh` — リポ固有 hook
- `<repo>/.claude/settings.json` — リポ固有 Claude 設定

### 2. ブランチモデルの確認

- 2 つ以上のリポを跨ぐ場合、着手前に各リポの default_branch を必ず gh api で取得する
  - `for r in <repos>; do echo "$r: $(gh api repos/<owner>/$r --jq .default_branch)"; done`
- サブエージェントへのプロンプトに「target base: <default>」として明示
- 「他リポの PR を参考に」と指示するときは本文構造のみ。base/head は対象リポの default に合わせる

### 3. 禁止事項

- `git pull origin main` のような **決め打ち pull**
  - clone 直後なら不要
  - 必要なら `git pull origin "$(git rev-parse --abbrev-ref origin/HEAD | sed 's@^origin/@@')"` で動的解決
- `gh pr create --base main` のような **決め打ち base 指定**
- サブエージェントに「クローンして修正」だけ指示し、リポの CLAUDE.md / .claude を読ませない指示

### 4. 横展開タスクは `ccow-cross-repo-dispatch` Skill を起動する

複数リポを跨ぐタスクは必ず Skill `ccow-cross-repo-dispatch` を呼び、上記チェックリストを機械的に実行する。
