#!/bin/bash
# Builds a ready to run port folder from a Steam copy of the demo, doing on the PC what the
# device patcher will do (gmtoolkit in a container with vorbis-tools):
#   build/assemble.sh <folder with data.win and audiogroup*.dat> <out dir>
# The out dir can be run with tests/localtest.sh, or copied to ports/deadestate on a device.
set -e
B="$(cd "$(dirname "$0")" && pwd)"; R="$(cd "$B/.." && pwd)"; G="$(realpath "$1")"; O="$(realpath -m "$2")"
"$B/fetch_deps.sh" >/dev/null
rm -rf "$O"; mkdir -p "$O/saves" "$O/w/assets" "$O/w/lib/arm64-v8a"
cp "$B/deps/gmloadernext.aarch64" "$O/"; cp -r "$B/deps/lib" "$O/"; cp "$R/port/deadestate/gmloader.json" "$O/"
cp "$G/data.win" "$O/w/assets/game.droid"; cp "$G"/audiogroup*.dat "$O/w/assets/"
cp -r "$R/port/deadestate/tools" "$O/w/tools"; cp "$B/deps/gmtk-x86_64/gmtoolkit.linux-x86_64" "$O/w/tools/gmtoolkit"
docker run --rm -v "$O:/o" -w /o/w/assets debian:bookworm bash -c '
  apt-get update -qq && apt-get install -y -qq vorbis-tools >/dev/null 2>&1
  mkdir -p /o/w/saves && /o/w/tools/gmtoolkit game.droid --config /o/w/tools/gmtoolkit.json
  chown -R '"$(id -u):$(id -g)"' /o'
mv "$O/w/saves/textures" "$O/saves/"
(cd "$O/w" && unzip -qo "$B/deps/runner-2.3.7.apk" lib/arm64-v8a/libyoyo.so lib/arm64-v8a/libc++_shared.so \
  && zip -q -0 -r "$O/deadestate.port" lib assets)
rm -rf "$O/w"; ls -la "$O"
