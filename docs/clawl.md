# Webクロールルール

## syosetu.comの場合

対象URL: https://ncode.syosetu.com/XXXXXXX/ (XXXXXXは作品毎に一意な値)

| 項目                   | CSSセレクタ            |
| :--------------------- | :--------------------- |
| 小説タイトル           | .p-novel\_\_title      |
| 作者名                 | .p-novel\_\_author a   |
| 各エピソードへのリンク | a.p-eplist\_\_subtitle |

### 各話

| 項目               | CSSセレクタ                  |
| :----------------- | :--------------------------- |
| エピソードタイトル | .p-novel\_\_subtitle-episode |
| エピソード内容     | .p-novel\_\_text             |

