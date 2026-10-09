#!/bin/bash
# Downloads the third party pieces the port needs into build/deps/, pinned and checked by MD5:
#  * gmloadernext.aarch64 and its bionic shim libs, the pre 2026-04-24 build PortMaster ships with
#    Hostile Lands (newer builds refuse the 2.3.x runner, see docs/PORTING.md)
#  * the GameMaker 2.3.7 Android wrapper APK (arm64 libyoyo.so + libc++_shared.so)
#  * gmtoolkit (x86_64 for building on a PC, aarch64 for the device patcher)
set -e
B="$(cd "$(dirname "$0")" && pwd)"; D="$B/deps"; mkdir -p "$D/lib/arm64-v8a"
PM=https://raw.githubusercontent.com/PortsMaster/PortMaster-New/c80727ab841fa1cae51068b4416015de0005842e/ports/hostilelands/hostilelands
GP="https://raw.githubusercontent.com/Fraxinus88/GMloader-ports/2b176790ff629b44fdbb4049306c1e8d9a346975/gmloader%20wrappers%20(APK)/2.x/2.3.7%20-%2017.apk"
GT=https://github.com/JeodC/gmtoolkit/releases/download/latest
get() { [ -f "$2" ] && echo "$3  $2" | md5sum -c --status && return; curl -fsSL -o "$2" "$1"; echo "$3  $2" | md5sum -c --quiet; }
get "$PM/gmloadernext.aarch64"               "$D/gmloadernext.aarch64"          0d2f4880314bcaebe4e0fefa6f058adf
get "$PM/lib/arm64-v8a/libcompiler_rt.so"     "$D/lib/arm64-v8a/libcompiler_rt.so" fe923cfe4bb934391ae16fc966bfb7fe
get "$PM/lib/arm64-v8a/libc++_shared.so"      "$D/lib/arm64-v8a/libc++_shared.so"  2c2c1c32815e6aa1e2a725a2ff3b1d32
get "$PM/lib/arm64-v8a/libm.so"               "$D/lib/arm64-v8a/libm.so"           b37f82bd7fcea9f582a2601ecebaf7cc
get "$PM/license/LICENSE.gmloader.txt"        "$D/LICENSE.gmloader.txt" "$(curl -fsSL "$PM/license/LICENSE.gmloader.txt" | md5sum | cut -d' ' -f1)"
get "$PM/license/LICENSE.bionic.txt"          "$D/LICENSE.bionic.txt"   "$(curl -fsSL "$PM/license/LICENSE.bionic.txt" | md5sum | cut -d' ' -f1)"
get "$GP"                                     "$D/runner-2.3.7.apk"              b7ec8029b34b16d9401f0022fa124af4
for a in linux-x86_64 aarch64; do
  [ -f "$D/gmtoolkit-$a.zip" ] || curl -fsSL -o "$D/gmtoolkit-$a.zip" "$GT/gmtoolkit-$a.zip"
done
(cd "$D" && unzip -qo gmtoolkit-linux-x86_64.zip -d gmtk-x86_64 && unzip -qo gmtoolkit-aarch64.zip -d gmtk-aarch64)
chmod +x "$D/gmloadernext.aarch64" "$D"/gmtk-*/gmtoolkit* 2>/dev/null || true
echo "deps ready in $D"
