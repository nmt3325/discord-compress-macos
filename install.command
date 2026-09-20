#!/bin/bash
# Discordに圧縮 v1.6.0 インストーラ
set -u
cd "$(dirname "$0")" || exit 1

RH="$(/usr/bin/dscl . -read "/Users/$(/usr/bin/id -un)" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}')"
case "$RH" in /Users/*) : ;; *) RH="$HOME" ;; esac
SERVICES="$RH/Library/Services"
APPS="$RH/Applications"
BIN="$RH/bin"
LSREG="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
PBS="/System/Library/CoreServices/pbs"

echo "==================================="
echo " Discordに圧縮 v1.6.0 を導入します"
echo "==================================="
echo "ホーム: $RH"
mkdir -p "$SERVICES" "$APPS" "$BIN"

echo
echo "[1/6] ファイルを配置"
APP_PATHS=()
for w in *.workflow; do
  [ -e "$w" ] || continue
  rm -rf "$SERVICES/$w"
  /usr/bin/ditto "$w" "$SERVICES/$w" && echo "  クイックアクション: $w"
  /usr/bin/xattr -dr com.apple.quarantine "$SERVICES/$w" 2>/dev/null
done
for a in *.app; do
  [ -e "$a" ] || continue
  rm -rf "$APPS/$a"
  /usr/bin/ditto "$a" "$APPS/$a" && echo "  アプリ: $a"
  /usr/bin/xattr -dr com.apple.quarantine "$APPS/$a" 2>/dev/null
  /usr/bin/codesign --force --deep -s - "$APPS/$a" >/dev/null 2>&1
  APP_PATHS+=("$APPS/$a")
done
/usr/bin/install -m 755 discord-compress.sh "$BIN/discord-compress" && echo "  コマンド: $BIN/discord-compress"

echo
echo "[2/6] アプリを LaunchServices に登録"
if [ -x "$LSREG" ] && [ ${#APP_PATHS[@]} -gt 0 ]; then
  "$LSREG" -f "${APP_PATHS[@]}" >/dev/null 2>&1 && echo "  OK"
else
  echo "  スキップ"
fi

echo
echo "[3/6] 右クリックメニューでの表示を有効化"
ENABLE_FAILED=0
for w in *.workflow; do
  [ -e "$w" ] || continue
  plist="$w/Contents/Info.plist"
  title="$(/usr/bin/plutil -extract NSServices.0.NSMenuItem.default raw -o - "$plist" 2>/dev/null)"
  bid="$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "$plist" 2>/dev/null)"
  if [ -z "$title" ] || [ -z "$bid" ]; then
    echo "  失敗: $w の識別情報を読めません" >&2
    ENABLE_FAILED=1
    continue
  fi
  status_key="$bid - $title - runWorkflowAsService"
  if /usr/bin/defaults write pbs NSServicesStatus -dict-add "$status_key" \
      '{"enabled_context_menu" = 1; "enabled_services_menu" = 1;}'; then
    echo "  有効: $title"
  else
    echo "  有効化に失敗: $title" >&2
    ENABLE_FAILED=1
  fi
done

echo
echo "[4/6] サービスキャッシュを更新"
[ -x "$PBS" ] && "$PBS" -flush >/dev/null 2>&1
[ -x "$PBS" ] && "$PBS" -update >/dev/null 2>&1
/usr/bin/killall -HUP Finder >/dev/null 2>&1
/usr/bin/killall Dock >/dev/null 2>&1
echo "  OK"

echo
echo "[5/6] 構成を確認"
"$BIN/discord-compress" --version 2>/dev/null || true
for a in "${APP_PATHS[@]}"; do
  bid="$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "$a/Contents/Info.plist" 2>/dev/null)"
  ver="$(/usr/bin/plutil -extract CFBundleShortVersionString raw -o - "$a/Contents/Info.plist" 2>/dev/null)"
  if /usr/bin/codesign --verify --deep "$a" >/dev/null 2>&1; then
    echo "  アプリ OK: $bid ($ver)"
  else
    echo "  アプリ署名の確認に失敗: $a" >&2
  fi
done

echo
echo "[6/6] Finder のクイックアクション設定を開きます"
echo "  動画を右クリック → クイックアクション → カスタマイズ でも確認できます"
open "x-apple.systempreferences:com.apple.ExtensionsPreferences" >/dev/null 2>&1 || true

echo
echo "===== 完了 ====="
echo "使い方"
echo "  A) 動画を右クリック → クイックアクション → Discord用に圧縮"
echo "  B) 動画を右クリック → このアプリケーションで開く → Discordに圧縮"
echo "  C) Launchpad から「Discordに圧縮」を起動してファイルを選ぶ"
echo "  D) ターミナル: discord-compress 動画.mp4"
if [ "$ENABLE_FAILED" -ne 0 ]; then
  echo
  echo "注意: 自動有効化に失敗しました。Finderで動画を右クリックし、"
  echo "      クイックアクション → カスタマイズ から手動で有効にしてください。"
fi
echo
echo "うまく動かないときはこの 1 行を実行して結果を送ってください:"
echo "  ~/bin/discord-compress --doctor"
echo
