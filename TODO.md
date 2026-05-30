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

- [ ] `NovelInfoParser` — タイトル・作者・あらすじをパース
- [ ] `EpisodeListParser` — 話インデックス・タイトル・URL をパース
- [ ] `EpisodeContentParser` — 本文をパース（ルビ・改行保持）

## 5. Library Manager

- [ ] `LibraryManager` actor を作成
  - [ ] 作品登録フロー（メタ情報取得 → エピソード一覧取得 → 本文一括取得）
  - [ ] リクエスト間遅延（1〜2 秒）
  - [ ] エラー分類（ネットワーク = リトライ可 / パース = スキップ）
- [ ] アプリ起動時に App Groups から URL を受け取り登録フローを呼ぶ処理

## 6. Share Extension

- [ ] 共有シートに表示される最小限の UI
- [ ] 受け取った URL を `UserDefaults(suiteName:)` に書き込む
- [ ] 書き込み後に Extension を閉じる

## 7. 書庫画面（Library）

- [ ] 作品一覧 `List` ビュー（タイトル・作者・保存話数・最終更新日時）
- [ ] 作品ごとのストレージ使用量表示
- [ ] 総ストレージ使用量表示
- [ ] 作品削除（スワイプ）
- [ ] `LibraryViewModel` — DB から取得・更新トリガー

## 8. Reader 画面

- [ ] `WKWebView` を `UIViewRepresentable` でラップ
- [ ] HTML テンプレートファイル（`reader.html`）を作成
  - [ ] CSS: `writing-mode: vertical-rl` / `column-width` / `scroll-snap-type: x mandatory`
  - [ ] ルビ（`<ruby>`）対応
- [ ] 横フリックでページ送り
- [ ] タップ領域でページ送り（左右端タップ）
- [ ] ページ位置の保存（DB）と復元
- [ ] JS ↔ Swift 通信（`WKScriptMessageHandler`）でスクロール位置取得
- [ ] `ReaderViewModel` — エピソード読み込み・位置管理

## 9. 設定画面

- [ ] フォント選択
- [ ] 文字サイズ
- [ ] 行間幅
- [ ] 上下左右マージン
- [ ] テーマ（システム / ライト / ダーク）
- [ ] 設定値を `UserDefaults` に保存し Reader に反映

## 10. テスト

- [ ] `EpisodeContentParser` ユニットテスト（フィクスチャ HTML 使用）
- [ ] `NovelInfoParser` ユニットテスト
- [ ] `EpisodeListParser` ユニットテスト
- [ ] `DatabaseClient` ユニットテスト（インメモリ DB）
- [ ] `HTTPClient` ユニットテスト（`URLProtocol` モック）
