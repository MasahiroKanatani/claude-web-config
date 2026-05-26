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
rm -f ~/.claude/settings.json
mkdir -p ~/.claude
cp "$SCRIPT_DIR/home/CLAUDE.md" ~/.claude/CLAUDE.md
cp "$SCRIPT_DIR/home/settings.local.json" ~/.claude/settings.local.json
