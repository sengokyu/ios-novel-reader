# TODO

## 0. プロジェクト初期設定

- [x] Swift Package を追加（GRDB.swift / SwiftSoup）
- [x] `SWIFT_STRICT_CONCURRENCY = complete` をビルド設定に追加（Swift 6.0 も同時設定）
- [x] App Groups entitlement を追加（本体 + Share Extension 共通）
- [x] Share Extension ターゲットを追加

## 1. Domain モデル定義

- [x] `Novel`（id, url, title, author, synopsis, totalEpisodes, updatedAt）
- [x] `Episode`（id, novelId, index, title, content, fetchedAt）
- [x] `ReadingPosition`（novelId, episodeId, pageOffset）

## 2. データベース層（GRDB）

- [x] `DatabaseClient` を作成（final class, @unchecked Sendable）
- [x] `DatabaseMigrator` でマイグレーション管理（v1: novels / episodes / reading_positions テーブル）
- [x] `NovelRepository` — 保存・取得・削除
- [x] `EpisodeRepository` — 保存・取得・削除・ストレージ集計
- [x] `ReadingPositionRepository` — 保存・取得

## 3. ネットワーク / クロール

- [x] `HTTPClient` — URLSession ラッパー（User-Agent 設定）
- [x] `SiteAdapterProtocol` — URL判定・novelTopURL・episodeURL を返す
- [x] `NarouAdapter` — なろう系サイト対応
  - [x] 作品情報ページ URL 生成（novelTopURL）
  - [x] エピソード一覧ページ URL 生成（novelTopURL と同一）
  - [x] 本文ページ URL 生成（episodeURL）

## 4. Parser（SwiftSoup）

- [x] `NovelInfoParser` — タイトル・作者・あらすじをパース
- [x] `EpisodeListParser` — 話インデックス・タイトル・URL をパース
- [x] `EpisodeContentParser` — 本文をパース（ルビ・改行保持、#novel_honbun の inner HTML を返す）

## 5. Library Manager

- [x] `LibraryManager` actor を作成
  - [x] 作品登録フロー（メタ情報取得 → エピソード一覧取得 → 本文一括取得）
  - [x] リクエスト間遅延（1 秒）
  - [x] エラー分類（エピソード個別のネットワーク/パースエラーはスキップ）
- [x] アプリ起動時に App Groups から URL を受け取り登録フローを呼ぶ処理（processPendingURL）

## 6. Share Extension

- [x] 共有シートに表示される最小限の UI（SLComposeServiceViewController）
- [x] 受け取った URL を `UserDefaults(suiteName:)` に書き込む
- [x] 書き込み後に Extension を閉じる

## 7. 書庫画面（Library）

- [x] 作品一覧 `List` ビュー（タイトル・作者・保存話数・最終更新日時）
- [x] 作品ごとのストレージ使用量表示
- [x] 総ストレージ使用量表示
- [x] 作品削除（スワイプ）
- [x] `LibraryViewModel` — DB から取得・更新トリガー

## 8. Reader 画面

- [x] `WKWebView` を `UIViewRepresentable` でラップ
- [x] HTML テンプレートファイル（`reader.html`）を作成
  - [x] CSS: `writing-mode: vertical-rl` / `column-width` / ダークモード対応
  - [x] ルビ（`<ruby>`）対応
- [x] タップ領域でページ送り（左: 先へ / 右: 戻る）
- [x] ページ位置の保存（DB）と復元
- [x] JS ↔ Swift 通信（`WKScriptMessageHandler`）でスクロール位置取得
- [x] `ReaderViewModel` — エピソード読み込み・位置管理

## 9. 設定画面

- [x] フォント選択（明朝体 / ゴシック体）
- [x] 文字サイズ
- [x] 行間幅
- [x] 上下左右マージン
- [x] テーマ（システム / ライト / ダーク）
- [x] 設定値を `UserDefaults` に保存し Reader に反映（CSS カスタムプロパティ経由）

## 10. テスト

- [x] `EpisodeContentParser` ユニットテスト（フィクスチャ HTML 使用）
- [x] `NovelInfoParser` ユニットテスト
- [x] `EpisodeListParser` ユニットテスト
- [x] `DatabaseClient` ユニットテスト（インメモリ DB）
- [x] `HTTPClient` ユニットテスト（`URLProtocol` モック）
