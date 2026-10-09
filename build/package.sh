#!/bin/bash
# Makes deadestate.zip, the folder a player installs: launcher, loader, shim libs, the 2.3.7 runner
# in deadestate.port (game data is added on the device by tools/patchscript), gmtoolkit for aarch64.
set -e
B="$(cd "$(dirname "$0")" && pwd)"; R="$(cd "$B/.." && pwd)"; O="$R/dist"
"$B/fetch_deps.sh" >/dev/null
rm -rf "$O"; mkdir -p "$O/deadestate/assets" "$O/deadestate/saves" "$O/deadestate/licenses" "$O/w"
cp "$R/port/Dead Estate.sh" "$O/"
cp -r "$R/port/deadestate/." "$O/deadestate/"
cp "$B/deps/gmloadernext.aarch64" "$O/deadestate/"; cp -r "$B/deps/lib" "$O/deadestate/"
cp "$B/deps/gmtk-aarch64/gmtoolkit.aarch64" "$O/deadestate/tools/"
cp "$B/deps/LICENSE.gmloader.txt" "$B/deps/LICENSE.bionic.txt" "$B/deps/gmtk-aarch64/gmtoolkit.LICENSE.txt" "$O/deadestate/licenses/"
(cd "$O/w" && unzip -qo "$B/deps/runner-2.3.7.apk" lib/arm64-v8a/libyoyo.so lib/arm64-v8a/libc++_shared.so \
  && zip -q -0 -r "$O/deadestate/deadestate.port" lib)
rm -rf "$O/w"
echo "Copy data.win, audiogroup1.dat and audiogroup2.dat from the Steam demo here." > "$O/deadestate/assets/PUT GAME FILES HERE.txt"
(cd "$O" && zip -q -r deadestate.zip "Dead Estate.sh" deadestate)
ls -la "$O"; unzip -l "$O/deadestate.zip" | tail -1
