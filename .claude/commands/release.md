---
description: リリースを作成する。ビルド・コミット・タグ・push・GitHub Release を一貫した手順とフォーマットで実行する。
user-invocable: true
---

# Release

バージョン引数: $ARGUMENTS (例: "0.4.0")。省略時はユーザーに確認する。

## 手順

### 1. 事前チェック

- `git status` でワークツリーがクリーンか確認する（未コミットの変更があれば先にコミットするか確認）
- `git tag -l` で既存タグと重複しないか確認する
- `swift build` でビルドが通ることを確認する

### 2. コミット & タグ

- 未コミットの変更がある場合、適切なコミットメッセージで `git commit` する
  - メッセージの末尾に `(v{VERSION})` を含める
- `git tag v{VERSION}` でタグを作成する

### 3. ビルド & zip

```
./build-app.sh
cd build && zip -r ClickEffect-{VERSION}.zip ClickEffect.app && cd ..
```

### 4. Push

```
git push origin main --tags
```

### 5. GitHub Release 作成

`gh release create` で以下のフォーマットに従ったリリースを作成する。

#### リリースノートのフォーマット

```markdown
## What's new

- **変更の要約** — 補足説明
- **変更の要約** — 補足説明
  - サブ項目がある場合はインデント
- 小さな変更はボールドなしでも可

**Full Changelog**: https://github.com/feb26/click-effect/compare/v{PREV_VERSION}...v{VERSION}
```

ルール:
- `## What's new` セクションのみ使う
- 各項目は **ボールド** で変更の要約を書き、`—` (em dash) の後に補足説明
- ユーザー視点で書く（実装詳細ではなく、何が変わったか）
- 末尾に必ず `**Full Changelog**` リンクを付ける（前バージョンとの比較）
- 前バージョンは `git tag -l --sort=-v:refname | head -2 | tail -1` で取得する

### 6. 完了確認

- `gh release view v{VERSION}` でリリースが正しく作成されたことを確認する
- リリース URL をユーザーに伝える
