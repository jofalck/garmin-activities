#!/bin/sh
# Builds every app for fr245 + fr245m into ./bin
set -e
cd "$(dirname "$0")"
export PATH=/opt/homebrew/opt/openjdk@21/bin:$PATH
SDK=$(ls -d "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks"/connectiq-sdk-mac-* | tail -1)
mkdir -p bin
for app in football xc-classic xc-skate randonee; do
  for dev in fr245 fr245m; do
    "$SDK/bin/monkeyc" -f "$app/monkey.jungle" -d $dev -y developer_key -l 3 -o "bin/$app-$dev.prg"
  done
done

# Forerunner 245 Music builds, committed so they can be downloaded on another PC
mkdir -p dist
for app in football xc-classic xc-skate randonee; do cp "bin/$app-fr245m.prg" "dist/$app.prg"; done
