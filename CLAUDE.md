# CLAUDE.md

プロジェクト概要・仕様は `README.md` と `docs/SPECIFICATION.md` を参照。

## Swift / iOS ベストプラクティス

### Swift 6 厳格な並行性

- UI 更新はすべて `@MainActor`。`DispatchQueue.main` は使わない。
- DB・ネットワークアクセスは `actor` で包んで共有可変状態を排除する。
- `SWIFT_STRICT_CONCURRENCY = complete` で `Sendable` 違反をエラーとして扱う。
- コールバックや `DispatchQueue` は書かず、`async/await` に統一する。
- `Task.detached` は本当に必要な場合のみ。

```swift
// Good
@MainActor
final class LibraryViewModel: ObservableObject { … }

actor DatabaseClient {
    func fetchNovels() async throws -> [Novel] { … }
}
```

### SwiftUI

- ビューはデータ変換のみ。ロジックは ViewModel / UseCase に置く。
- `@Observable`（iOS 17+）を優先し、`ObservableObject` は iOS 16 以下対応時のみ。
- `@State` はビューローカルな UI 状態のみ。ドメイン状態は ViewModel に持たせる。
- ViewModel の依存はプロトコルか closure injection でプレビュー・テスト時に差し替え可能にする。
- `List` / `LazyVStack` の `id:` は安定した値にする（`UUID()` を毎回生成しない）。

### WKWebView (縦書き Reader)

- `WKWebView` は `UIViewRepresentable` でラップして SwiftUI に組み込む。
- HTML テンプレートはバンドル内 `.html` ファイルに分離し、Swift コードに埋め込まない。
- JS ↔ Swift 通信は `WKScriptMessageHandler` を使い、`evaluateJavaScript` の乱用を避ける。

### GRDB

- スキーマ変更は `DatabaseMigrator` で番号付きマイグレーションとして管理する。既存テーブルを直接変更しない。
- 読み取りは `DatabaseQueue.read`、書き込みは `asyncWrite` を使い分ける。
- モデルは `FetchableRecord & PersistableRecord & Codable` を採用する。
- N+1 を防ぐため `including(all:)` / `including(required:)` で一括取得する。
- テストはインメモリ DB（`DatabaseQueue(configuration:)` で `.inMemory`）を使う。

### Share Extension

- App Groups 識別子: `group.cc.sengokyu.Tundokuko`
- Extension → 本体への受け渡しは `UserDefaults(suiteName:)` に URL を書き込み、本体起動時に処理する。
- 重い処理（クロール・DB 書き込み）は Extension では行わず本体に委ねる。

### ネットワーク / クロール

- `URLSession` のみ使用。サードパーティ HTTP ライブラリは導入しない。
- リクエスト間に 1〜2 秒の遅延を入れる。
- ネットワーク通信のテストは `URLProtocol` のモックで差し替える。

### エラーハンドリング

- エラーは `enum` で定義し `LocalizedError` に準拠させる。
- `try?` で握りつぶさず、画面にフィードバックするかログに残す。

### コード規約

- マジックナンバーは定数または `enum` に切り出す。
- `private` / `public` を明示する（`internal` はデフォルトなので省略可）。
- コメントは WHY が自明でない場合のみ書く。WHAT はコードで表現する。

## 依存ライブラリ

| ライブラリ | 用途          |
| ---------- | ------------- |
| GRDB.swift | SQLite ORM    |
| SwiftSoup  | HTML パーサー |

上記以外のサードパーティライブラリは原則追加しない。

## 開発フロー

- 機能追加前に `docs/SPECIFICATION.md` を確認する。
- Domain モデルを先に定義し、UI は後から作る。
- Parser の変更はサイト別 Adapter 内に閉じ込め、他レイヤーに影響させない。
- DB スキーマ変更は必ずマイグレーションを追加する（既存テーブルの直接変更禁止）。
- Share Extension と本体で共通コードが必要な場合は Framework ターゲットに切り出す。

## 特別なオーダー

- 実作業前に方針を検討し提示すること
- TODOに従いタスクを実行すること
- タスクを細分化する必要があればTODOを更新すること
- コミットは文脈に従い、なるべく小さくすること
- 決めた仕様があればドキュメントに残すか問い合わせること
- 追加必要なソフトウェアがあればmiseかbrewを使用してインストールすること。あるいは私に依頼すること

