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

## 今月のステージ

タイトル画面の「今月のステージに挑戦」から遊ぶ、月替わりの特別ステージ。本編とは別のランキング（`mode = 'monthly-YYYY-MM'`）で競う。

### 来月のステージを追加する

`index.html` の `const MONTHLY = { ... }` に、日本時間の年月をキーにして1件足す。その月に入ると自動で切り替わる（設定のない月は、いちばん新しい過去の設定を表示）。

| 項目 | 内容 |
|---|---|
| `title` / `short` | 画面に出す名前（例：`11月：○○`）と短い名前 |
| `base` | 地形と敵の動きの元にする本編ステージ（1〜4） |
| `look` | 地形の色 `{ reef:塗り, edge:輪郭 }` |
| `order` / `endT` | 出てくる敵・仕掛けの順番（`fan` `fanLow` `dash` `carrier` `turrets` `rear` `wall` `vents`）と、ボスまでの秒数 |
| `boss` / `bossName` / `tint` | ボスの種類（`core` `jelly` `fort` `worm`）と表示名。`tint` は深淵クラゲの色替え |
| `lives` / `capsX2` / `startItems` | ルール：残機、カプセル2倍、最初から付く強化 |
| `rule` | タイトル画面に出すルール説明 |
| `tag` | ステージ開始時の見出しに添える短いルール名（例：`1機勝負`） |
| `tunnel`（任意） | うねるトンネル地形。`[{ len, center, width }, ...]` を並べると、通り道の中心の高さ（`center`）と幅（`width`）が、次の点まで `len` px かけてなめらかに変わる。最後まで行くと最初に戻る。天井と床が一緒に上下し、幅が狭まったり広がったりする |
| `swim`（任意） | 水中ルール。`{ sink, current }` で、機体が毎秒 `sink` px 沈み、`current` px 横に流される（マイナスで後ろ向き）。泡の演出が付く |

### 来月のステージを先に試す

アドレスの最後に `#preview-2026-11` のように年月を付けて開くと、その月の設定で遊べる（例：`https://blue-leaf-striker-ubsf.vercel.app/#preview-2026-11`）。プレビュー中はランキングに登録されない。


ビルド不要の静的サイト。Vercel でこのリポジトリを Import し、設定を変えずに Deploy する。

## ランキング

- 画面には「月間」「年間」の2つを切り替えて表示する（日本時間の月初・年初で区切る）。登録1回につき1行で、表示は同じ名前の最高記録だけ。

- `scores` テーブルは誰でも読めるが、直接の書き込みはできない（RLS）。
- 登録は `submit_score(p_name, p_score)` 関数だけを通す。名前は12文字まで、スコアは 1〜500,000、全体で1分あたり30件まで。
- 各行に、使った機体（LEAF / LANCE）とアイテムの使い方（AUTO / MANUAL）を表示する。途中で MANUAL に切り替えたプレイは MANUAL として記録。
  これを記録するには `supabase/2026-10-ship-items.sql` を SQL Editor で1回実行する（実行前でもランキングは動き、機体・アイテムの表示が出ないだけ）。
- `config.js` に入れてよいのは publishable（anon）キーだけ。secret / service_role キーは絶対に入れない。
