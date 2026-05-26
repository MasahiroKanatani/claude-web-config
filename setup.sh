#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# gh CLI のインストール
# apt update の失敗（PPA の 403 等）で apt install がスキップされないよう || true を付ける
apt update || true
apt install -y gh

# npm registry をフラット社のプロキシから公式に戻す
for npmrc in /home/user/*/.npmrc; do
  if [ -f "$npmrc" ]; then
    sed -i 's|registry=https://npm.flatt.tech/|registry=https://registry.npmjs.org/|' "$npmrc"
  fi
done

# git remote URL をプロキシ（127.0.0.1）から GitHub に変換して gh CLI が動作するようにする
for gitdir in /home/user/*/.git; do
  if [ -d "$gitdir" ]; then
    repo_dir="$(dirname "$gitdir")"
    url="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"
    if [ -n "$url" ]; then
      github_path="$(echo "$url" | sed -n 's|.*127\.0\.0\.1.*/git/\(.*\)|\1|p')"
      if [ -n "$github_path" ]; then
        git -C "$repo_dir" remote set-url origin "https://github.com/${github_path}.git"
      fi
    fi
    git -C "$repo_dir" config user.name "${GH_NAME}"
    git -C "$repo_dir" config user.email "${GH_EMAIL}"
  fi
done

# Claude 設定ファイルを配置
# ~/.claude/CLAUDE.md は環境初期化で上書きされないため従来通り配置する
mkdir -p ~/.claude
cp "$SCRIPT_DIR/home/CLAUDE.md" ~/.claude/CLAUDE.md

# ~/.claude/settings.json は Claude Code on the Web のセッション初期化で
# 必ずデフォルトテンプレに上書きされるため使えない
# （公式: "user-level settings don't carry over to cloud sessions"）。
# 代わりに各リポジトリ配下の .claude/settings.local.json に配置する。
# .claude/settings.local.json はプロジェクトスコープで読み込まれ、
# かつ慣習的に git 管理外なので個人専用設定として機能する。
for gitdir in /home/user/*/.git; do
  if [ -d "$gitdir" ]; then
    repo_dir="$(dirname "$gitdir")"
    mkdir -p "$repo_dir/.claude"
    cp "$SCRIPT_DIR/home/settings.local.json" "$repo_dir/.claude/settings.local.json"
    # .gitignore に未登録のリポジトリで誤コミットしないよう
    # .git/info/exclude（リポジトリ単位の個人 ignore）にも登録する
    if ! grep -qxF '.claude/settings.local.json' "$gitdir/info/exclude" 2>/dev/null; then
      echo '.claude/settings.local.json' >> "$gitdir/info/exclude"
    fi
  fi
done
