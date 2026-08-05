#!/bin/bash
# SwiftExec — one-line installer. Clean reinstall of Roblox + the executor.
set -euo pipefail
RAW="https://raw.githubusercontent.com/pleglou26-oss/Socrate_Executor_download/main"
ROB="/Applications/Roblox.app"
DEST="/Applications/SwiftExec.app"
say(){ printf "\033[32m▸\033[0m %s\n" "$1"; }
die(){ printf "\033[31m✖ %s\033[0m\n" "$1"; exit 1; }

[ "$(uname -m)" = "arm64" ] || die "Apple Silicon (arm64) only."
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Always wipe Roblox + the executor and reinstall clean.
pkill -9 -x RobloxPlayer 2>/dev/null || true
pkill -9 -f SwiftExec 2>/dev/null || true
rm -rf "$DEST" 2>/dev/null || sudo rm -rf "$DEST" || true

say "downloading the latest Roblox (clean reinstall)..."
VER=$(curl -fsS -m 15 "https://clientsettingscdn.roblox.com/v2/client-version/MacPlayer" | grep -oE '"clientVersionUpload":"[^"]*"' | cut -d'"' -f4)
[ -n "$VER" ] || die "could not fetch the Roblox version"
curl -fL "https://setup.rbxcdn.com/mac/arm64/${VER}-RobloxPlayer.zip" -o "$TMP/roblox.zip" || die "Roblox download failed"
unzip -oq "$TMP/roblox.zip" -d "$TMP/rbx" || die "unzip failed"
rm -rf "$ROB" "/Applications/RobloxPlayer.app" 2>/dev/null || sudo rm -rf "$ROB" "/Applications/RobloxPlayer.app"
mv "$TMP/rbx/RobloxPlayer.app" "$ROB" 2>/dev/null || sudo mv "$TMP/rbx/RobloxPlayer.app" "$ROB"
[ -d "$ROB" ] || die "Roblox install failed"
say "Roblox $VER installed"

say "downloading SwiftExec..."
curl -fsSL "$RAW/SwiftExec.app.tar.gz" -o "$TMP/app.tgz" || die "download failed"
tar -xzf "$TMP/app.tgz" -C "$TMP" || die "extract failed"
cp -R "$TMP/SwiftExec.app" "$DEST" 2>/dev/null || sudo cp -R "$TMP/SwiftExec.app" "$DEST"
xattr -cr "$DEST" 2>/dev/null || true

# Drop libsocrate.dylib into Roblox.app so a patched Roblox always finds it.
# Adding it is always safe; the first Attach patches Roblox to actually load it.
# (We never REMOVE it — that is what breaks a patched Roblox.)
say "installing libsocrate.dylib into Roblox..."
curl -fsSL "$RAW/libsocrate.dylib" -o "$TMP/libsocrate.dylib" || die "dylib download failed"
MAC="$ROB/Contents/MacOS"
cp "$TMP/libsocrate.dylib" "$MAC/libsocrate.dylib" 2>/dev/null || sudo cp "$TMP/libsocrate.dylib" "$MAC/libsocrate.dylib" || die "could not install dylib into Roblox.app"
xattr -dr com.apple.quarantine "$MAC/libsocrate.dylib" 2>/dev/null || true

say "launching SwiftExec..."
open "$DEST"
printf "\n\033[32mdone ✅\033[0m\n"
echo "  1. Unlock with your licence key"
echo "  2. Open Roblox"
echo "  3. Click Attach, then ▶ Play"
