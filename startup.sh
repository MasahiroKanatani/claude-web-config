#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# SessionStart hook から毎セッション呼ばれる補正処理。
# 環境キャッシュから resume された場合や fresh clone でファイルが消えた場合に備え、
# git remote / git config / CWD project scope 設定を毎回確実な状態に揃える。
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

# /home/user/.claude（Claude プロセスの CWD project scope）の設定を再配置
mkdir -p /home/user/.claude
cp "$SCRIPT_DIR/home/CLAUDE.md" /home/user/.claude/CLAUDE.md
cp "$SCRIPT_DIR/home/settings.local.json" /home/user/.claude/settings.json
