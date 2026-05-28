---
name: ccow-pr-body-style
description: Claude Code on the Web (CCOW) で GitHub Pull Request の本文を書くときに必ず参照する。AI らしい冗長で読みにくい文章を防ぎ、レビューしやすい本文にするための文体ガイド。「概要」「変更内容」「やらないこと」の 3 節に適用する (他の節は対象外)。triggered by PR の作成、PR 本文編集、gh pr create、gh pr edit --body 等。
allowed-tools: Read(**)
---

# PR 本文の書き方 (概要 / 変更内容 / やらないこと)

このスキルは PR 本文 3 節「概要」「変更内容」「やらないこと」の書き方ガイド。他の節 (確認事項 / セキュリティ / ドキュメント / レビュー / 参考情報) は対象外で、各リポの PR テンプレに従う。

## 基本姿勢

PR 本文を書く前にこう自問する:

> 「会話を知らない人がこの差分だけ見たとき、何が分からないか?」

その回答を本文にする。回答が無ければ概要 1 文で十分。回答が複雑なら長くなる。**長さは結果**であって目標ではない。短くする目的で必要な情報を落とさない。

## 書くもの (差分では分からないこと)

1. **なぜそうしたか** — 動機、関連 Issue
2. **判断したポイント** — 他の選択肢ではなくこれを選んだ理由、トレードオフ
3. **差分では見えない影響** — 他のリポやサービスへの波及、後方互換性、デプロイ順序、必要な ops 手順 (env 変数、マイグレーション、再起動)
4. **どう検証したか** — CI で見えない部分。手元での動作確認の有無
5. **わざと範囲外にしたこと** — 誤解を招く範囲だけ書く。「全 PR で template-injection だけ対応、permissions は別 PR」のような分担

## 書かないもの (差分で分かること)

- ファイル名と一行レベルの変更内容の列挙
- before/after のコード片 (差分タブで読める)

## 文体ルール

1. **決まり文句を避ける**
   - 「〜の横展開として」「監査結果に基づき」「リスクを低減する」「影響範囲を限定する」「ベストプラクティスに従い」「を実施する」のような型は使わない
2. **回りくどい言い回しを避ける**
   - 「〜することにより〜することができる」 → 「〜できる」
   - 「〜について言及する」 → 「〜を書く」「〜に触れる」
   - 「〜の対応を行う」 → 「〜する」「〜を直す」
3. **不要なカタカナ専門用語を使わない**
   - 読み手がすぐ分かる日本語があるならそちらを使う
   - 技術用語そのもの (zizmor、template-injection 等) はそのまま OK
4. **同じ内容を複数の節で繰り返さない**
   - 概要に書いたことを「変更内容」で再度言わない
5. **A/B/C と必ず章分けしない**
   - 修正が 1 種類なら 1 行、複数あれば軽い箇条書きで足りる

## サンプル

### 悪い例

```
classmethod-aws/kerner#3669 の横展開。zizmor v1.25.2 による監査結果に基づき、
GitHub Actions の CI/CD ワークフローに対して以下 3 種の finding を修正する。

### A. excessive-permissions (5 件修正)

トップレベル `permissions: {}` を追加し、各 job に必要最小限の権限を明示:
- update_open_api.yml: `permissions: {}` + job に `contents: write` / `pull-requests: write`
- update_react_best_practices_skill.yml: 同上
- versioning.yml: `permissions: {}` + 各 job に `contents: write`

### B. github-env (1 件修正)
...
```

### 良い例

```
zizmor の指摘を 3 種類まとめて潰した。

- excessive-permissions: 該当 5 ワークフローを `permissions: {}` ベースに移行。書き込みが必要な job だけ contents: write / pull-requests: write を明示
- github-env: setup-terraform を $GITHUB_ENV → composite outputs に変更。AWS_ACCOUNT_ID の consumer は無いので呼び出し側は無変更
- ref-version-mismatch: claude-code-action 系の SHA pin コメントを v1.0.128 に揃えただけ

template-injection (slack-notify-end) は別 PR。

検証は uvx zizmor で対象 finding 0 を確認。CI のみの変更なのでユニットテスト等は走らせていない。
```

## やらないこと の節について

PR テンプレに `## やらないこと` 節があり、本 PR と混同しそうな範囲があれば書く (例: 「同じ監査の別カテゴリは別 PR」)。混同のおそれが無いなら「N/A」で OK、無理に項目を埋めない。
