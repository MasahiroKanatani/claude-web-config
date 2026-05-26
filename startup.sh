#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# SessionStart hook から毎セッション呼ばれる補正処理。
# 環境キャッシュから resume された場合や fresh clone でファイルが消えた場合に備え、
# git remote / git config / プロジェクトスコープ設定を毎回確実な状態に揃える。
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

    # .claude/settings.local.json を再配置（fresh clone や resume で消えた場合の補正）
    mkdir -p "$repo_dir/.claude"
    cp "$SCRIPT_DIR/home/settings.local.json" "$repo_dir/.claude/settings.local.json"
    if ! grep -qxF '.claude/settings.local.json' "$gitdir/info/exclude" 2>/dev/null; then
      echo '.claude/settings.local.json' >> "$gitdir/info/exclude"
    fi
  fi
done
