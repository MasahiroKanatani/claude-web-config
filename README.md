# claude-web-config

Claude Code on the Web のパーソナルセットアップ設定。

## 構成

```
setup.sh                  # メインセットアップスクリプト（環境キャッシュ未作成時に走る）
startup.sh                # SessionStart hook から毎セッション呼ばれる補正処理
home/
  CLAUDE.md               # ~/.claude/CLAUDE.md に配置
  settings.local.json     # 各リポジトリの .claude/settings.local.json に配置
                          # （SessionStart + PreToolUse の hook を含む）
```

## WebUI セットアップスクリプト設定

Claude Code on the Web の環境設定（WebUI）のセットアップスクリプトに以下を設定する：

```bash
#!/bin/bash
git clone https://github.com/MasahiroKanatani/claude-web-config.git /tmp/claude-web-config
bash /tmp/claude-web-config/setup.sh
```

## setup.sh の内容

- `gh` CLI のインストール（`apt update || true` で PPA 403 エラーを回避）
- npm registry を公式に戻す
- git remote URL をプロキシから GitHub に変換（`gh` CLI が動作するよう）
- `~/.claude/CLAUDE.md` を配置
- 各リポジトリ配下の `.claude/settings.local.json` に hook 設定を配置
- 各リポジトリの `.git/info/exclude` に `.claude/settings.local.json` を登録（誤コミット防止）

## startup.sh の内容

`home/settings.local.json` の SessionStart hook から毎セッション呼ばれる補正処理。
環境キャッシュから resume されたり fresh clone でファイルが消えた場合でも、
毎セッション確実な状態へ揃え直す：

- git remote URL の再修正（プロキシ → GitHub）
- git config user.name / user.email の再設定
- 各リポジトリの `.claude/settings.local.json` の再配置

## なぜ `~/.claude/settings.json` ではなく各リポジトリの `.claude/settings.local.json` か

Claude Code on the Web では、user-level の `~/.claude/settings.json` は
セッション初期化のタイミングで強制的にデフォルトテンプレに上書きされる。
このため、ユーザー個人の hook 設定を `~/.claude/settings.json` に書いても消える。

公式ドキュメント（[Claude Code on the web](https://code.claude.com/docs/en/claude-code-on-the-web)）:

> SessionStart hooks can also be defined in your user-level
> `~/.claude/settings.json` locally, but **user-level settings don't carry over
> to cloud sessions**. In the cloud, only hooks committed to the repo run.

そこで、各リポジトリの `.claude/settings.local.json`（プロジェクトスコープ、
慣習的に `.gitignore` 対象で git 管理外）に hook を配置することで、
クラウドセッションで個人専用設定を強制適用できる。

`.git/info/exclude` への登録は、リポジトリの `.gitignore` を変更せず
個人スコープで git 管理外を担保するための補強策（kerner は既に
`.gitignore` 登録済み、corvina は未登録なので `.git/info/exclude` で補う）。

## 注意事項

- このリポジトリに秘密情報（トークン、パスワード等）は絶対に含めない
- `settings.local.json` は GitHub MCP の使用を禁止し、`gh` CLI の使用を強制するフック設定
