---
name: ccow-cross-repo-dispatch
description: 2つ以上の GitHub リポジトリへ並行/連続して変更を入れる場合に必ず起動する。横展開、複数リポへの監査結果反映、同じ修正の複数プロジェクト適用、複数リポへのサブエージェント並列ディスパッチ等。各リポの default_branch とリポ固有 AI 設定 (CLAUDE.md / .claude/*) を確認しサブエージェントプロンプトに明示することで、ベース不一致や規約違反による誤った PR を防ぐ。
allowed-tools: Bash(gh:*), Bash(echo:*), Bash(for:*), Bash(printf:*), Bash(find:*), Bash(cat:*), Bash(ls:*), Bash(basename:*), Bash(sed:*), Read(**)
---

# 横展開タスク準備チェックリスト

順番に **全て実行する**。各ステップの結果は控えてサブエージェントへのプロンプトに反映する。

## 1. 対象リポの確定

ユーザに対象リポ (fully qualified name: owner/repo) を確認。

## 2. default_branch を一括取得

```bash
for r in <repos>; do
  echo "$r: $(gh api repos/$r --jq .default_branch)"
done
```

## 3. 各リポの AI/Claude 設定を棚卸し

クローン済みなら find、未クローンなら `gh api repos/$r/contents/.claude` で:

```bash
for r in <repos>; do
  name=$(basename "$r")
  dir="/home/user/$name"
  [ -d "$dir" ] || continue
  echo "=== $r ==="
  for f in CLAUDE.md AGENTS.md .claude/CLAUDE.md .claude/settings.json; do
    [ -f "$dir/$f" ] && echo "  - $f"
  done
  find "$dir/.claude" -maxdepth 3 -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' \) 2>/dev/null | sed "s|^$dir/|  - |"
done
```

## 4. サブエージェントプロンプトのテンプレ

各サブエージェントの prompt 冒頭に **必ず** 以下を含める:

```
target repo: <owner>/<repo>
target base branch: <default_branch>     ← 手順 2 で取得した値
target head branch: chore/<topic>

着手前に必ず以下を読み運用ルールに従う:
- <repo>/CLAUDE.md (または .claude/CLAUDE.md)
- <repo>/AGENTS.md
- <repo>/.claude/rules/ 配下の関連ルール
- <repo>/.claude/agents/ — 該当分野の専用 sub-agent があれば優先使用
- <repo>/.claude/commands/ — 該当タスクの定型コマンドがあれば使う
- <repo>/.claude/skills/ — リポ固有 Skill (例: create-pr) があればそれを優先

PR 作成:
- リポに .claude/skills/create-pr があればそれを使う
- なければユーザーグローバル create-pr Skill を使う
- base は必ず target base に合わせる

禁止:
- git pull origin main のような決め打ち pull
- gh pr create --base main のような決め打ち base 指定
```

## 5. ディスパッチ後の最終確認

各サブエージェントから完了報告を受けたら以下を verify:

```bash
gh api repos/<owner>/<repo>/pulls/<pr> --jq '{base: .base.ref, head: .head.ref}'
gh api repos/<owner>/<repo>/compare/<default>...<head> --jq '{ahead_by, behind_by}'
# 期待: base = target base、ahead が想定 commit 数、behind = 0 (rebase 済みなら)
```
