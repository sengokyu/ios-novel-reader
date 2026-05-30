# Novel Reader for iPhone

Kindle風の縦書きWeb小説リーダー。

## 概要

Safari共有メニューからWeb小説URLを登録し、アプリ内で作品情報・本文を取得してローカル保存する。
読書体験を最優先とし、縦書き・ページ送り・オフライン閲覧を提供する。

## 主な機能

- Safari共有から作品登録
- なろう系サイト対応
- フォアグラウンド更新
- ローカル全文キャッシュ
- オフライン読書
- Kindle風ページ送り
- 縦書き表示
- 読書位置保存
- 書庫管理
- ストレージ使用量表示
- ダークモード

## 技術スタック

- Swift 6
- SwiftUI
- WKWebView
- SQLite
- GRDB
- SwiftSoup
- App Groups
- Share Extension

## アーキテクチャ

Safari Share Extension
↓
Library Manager
↓
Crawler
↓
Parser
↓
SQLite
↓
Reader

## 開発方針

- iOS専用
- 広告なし
- ログイン不要
- サーバ不要
- Parser更新はアプリ更新で対応
