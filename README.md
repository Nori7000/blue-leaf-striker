# BLUE LEAF STRIKER

スマホのブラウザで遊べる横スクロールシューティング。Blue Leaf Studio 制作。

## ファイル構成

| パス | 内容 |
|---|---|
| `index.html` | ゲーム本体（HTML / CSS / JavaScript を1ファイルに収録） |
| `config.js` | ランキング用 Supabase の接続先（Project URL と publishable キー） |
| `music/` | BGM（SUNO Pro プランで生成。商用利用可） |
| `manifest.webmanifest`, `icon.svg` | ホーム画面に追加したときのアプリ名とアイコン |
| `supabase/schema.sql` | ランキング用テーブルと登録用関数。Supabase の SQL Editor で実行する |

## 公開

ビルド不要の静的サイト。Vercel でこのリポジトリを Import し、設定を変えずに Deploy する。

## ランキング

- `scores` テーブルは誰でも読めるが、直接の書き込みはできない（RLS）。
- 登録は `submit_score(p_name, p_score)` 関数だけを通す。名前は12文字まで、スコアは 1〜200,000、全体で1分あたり30件まで。
- `config.js` に入れてよいのは publishable（anon）キーだけ。secret / service_role キーは絶対に入れない。
