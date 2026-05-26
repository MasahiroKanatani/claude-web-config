# claude-web-config

Claude Code on the Web のパーソナルセットアップ設定。

## 構成

```
setup.sh                  # メインセットアップスクリプト
home/
  CLAUDE.md               # ~/.claude/CLAUDE.md に配置
  settings.local.json     # ~/.claude/settings.local.json に配置
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
- `~/.claude/CLAUDE.md` / `~/.claude/settings.local.json` を配置

## 注意事項

- このリポジトリに秘密情報（トークン、パスワード等）は絶対に含めない
- `settings.local.json` は GitHub MCP の使用を禁止し、`gh` CLI の使用を強制するフック設定
