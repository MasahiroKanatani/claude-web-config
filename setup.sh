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

# CWD（/home/user）で git config を引いたときにも正しいユーザー情報が見えるよう
# グローバル設定にも反映する
git config --global user.name "${GH_NAME}"
git config --global user.email "${GH_EMAIL}"

# Claude 設定ファイルを配置
# ~/.claude/CLAUDE.md は環境初期化で上書きされないため従来通り配置する
mkdir -p ~/.claude
cp "$SCRIPT_DIR/home/CLAUDE.md" ~/.claude/CLAUDE.md

# ~/.claude/settings.json は Claude Code on the Web のセッション初期化で
# デフォルトテンプレに上書きされるため使えない（公式: "user-level settings
# don't carry over to cloud sessions"）。
#
# Claude プロセスの CWD は /home/user なので、/home/user/.claude/ が
# project scope として読まれる。ここはどのリポジトリにも属さない（git 管理外）
# ため、個人専用設定を配置する場所として最適。
mkdir -p /home/user/.claude
cp "$SCRIPT_DIR/home/CLAUDE.md" /home/user/.claude/CLAUDE.md
cp "$SCRIPT_DIR/home/settings.local.json" /home/user/.claude/settings.json

# Skill 配布 (~/.claude/skills と project scope の両方)
for target in ~/.claude/skills /home/user/.claude/skills; do
  mkdir -p "$target"
  if [ -d "$SCRIPT_DIR/home/skills" ]; then
    cp -r "$SCRIPT_DIR/home/skills/." "$target/"
  fi
done
