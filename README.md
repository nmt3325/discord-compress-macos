# Discordに圧縮 v1.6.0

どんな動画でも Discord 無料プランの上限（20 MB）に収まるよう自動圧縮する macOS ツールです。
Apple Silicon（M1/M2/M3）では GPU（VideoToolbox）を使って高速に圧縮します。

## 導入

1. `install.command` を**右クリック → 開く** （ダブルクリックではブロックされます）
2. 確認ダイアログが出たら「開く」
3. 動画を右クリック → クイックアクション → カスタマイズ で
   「Discord用に圧縮」が有効になっていることを確認する

ffmpeg が必要です（`brew install ffmpeg`）。

## 使い方（どれでも OK）

| 方法 | 手順 |
| --- | --- |
| A. クイックアクション | 動画を右クリック → クイックアクション → Discord用に圧縮 |
| B. アプリで開く | 動画を右クリック → このアプリケーションで開く → Discordに圧縮 |
| C. ドラッグ＆ドロップ | `~/Applications/Discordに圧縮.app` に動画をドロップ |
| D. Launchpad | 「Discordに圧縮」を起動してファイルを選ぶ |
| E. ターミナル | `discord-compress 動画.mp4` |

サイズを選びたいときは「Discord用に圧縮（サイズを選ぶ）」を使います。
（10 MB / 20 MB / 50 MB（Nitro Basic）/ 500 MB（Nitro））

出力は元ファイルと同じ場所に `_discord.mp4` として保存され、完了すると Finder で選択表示されます。

## v1.6.0 の変更点（Finder右クリック修正版）

- `install.command` のサービス有効化キーを、無効な `(null)` から各ワークフローの
  `CFBundleIdentifier` に修正
- `defaults` に渡す辞書の誤ったエスケープを修正し、失敗を隠さず表示
- Apple純正動画サービスと同じ `servicesMenu` / `fileSystemObject.movie` 構成に統一
- クイックアクションとアプリのバージョンをすべて `1.6.0` に更新し、古いキャッシュと区別
- クイックアクションはBundle ID検索より実際のアプリパスを優先し、開始時の待ち時間を短縮
- 設定案内を「動画を右クリック → クイックアクション → カスタマイズ」に修正

## v1.5.0 の変更点（右クリックが無反応な問題の対策）

- クイックアクションからアプリへの受け渡しを**バンドル ID 指定**に変更し、起動したかを
  マーカーファイルで確認。反応がなければパス指定→直接実行の順に自動フォールバック
- **無反応で終わらない**：ファイルを受け取れない場合や失敗時は必ず通知を表示
- **必ず痕跡が残る**：`/tmp/discord-compress-qa.log` と macOS 統合ログに記録
- サービス経由で `$HOME` が違う環境でも実ホームを解決してログ・設定を読む
- 入力タイプを緩和（`public.movie` に加えて `public.audiovisual-content`）
- インストーラがコンテキストメニュー表示を明示的に有効化し、アプリを LaunchServices に登録
- `--doctor` に右クリック診断（サービス有効状態、ワークフロー構成、実行記録）を追加

## うまく動かないとき

```
~/bin/discord-compress --doctor
```

「右クリック実行の記録」の見方：

- `記録なし` → 右クリックからスクリプト自体が呼ばれていません。
  設定 → 一般 → ログイン項目と機能拡張 → 機能拡張 → Finder でチェックを入れ直し、
  `install.command` をもう一度実行してください（それでも出ないときは一度ログアウト）。
  その間も「このアプリケーションで開く」やドロップで圧縮できます。
- `no input -> abort` → ファイルが渡されていません。`install.command` を再実行。
- `handoff path ok` または `handoff bundle ok` → 正常。アプリ側で圧縮しています。
- `inline fallback start` → アプリが使えないため直接圧縮中（進捗は通知表示）。

詳しいログ：

```
tail -40 ~/Library/Logs/discord-compress.log
log show --last 10m --info --predicate 'eventMessage CONTAINS "discord-compress"' --style compact
```

## オプション（ターミナル）

```
discord-compress [オプション] 動画ファイル...
  --target N       目標サイズ MB（既定 20）
  --ask            サイズを選ぶダイアログを出す
  --out-dir DIR    出力先フォルダ
  --suffix STR     出力ファイル名の接尾辞（既定 _discord）
  --encoder auto|gpu|cpu   エンコーダの選択（既定 auto = Apple Silicon なら GPU）
  --hevc           H.265 で圧縮（同じ画質でより小さいが互換性は落ちる）
  --progress auto|bar|notify|none
  --no-skip        すでに入るサイズでも圧縮する
  --doctor         診断を表示
```

## アンインストール

```
rm -rf ~/Library/Services/"Compress for Discord.workflow" \
       ~/Library/Services/"Compress for Discord (choose size).workflow" \
       ~/Applications/Discordに圧縮.app \
       ~/Applications/Discordに圧縮（サイズを選ぶ）.app \
       ~/bin/discord-compress
/System/Library/CoreServices/pbs -flush; killall Finder
```
