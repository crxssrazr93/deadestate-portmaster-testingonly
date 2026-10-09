#!/bin/bash
# Runs the real aarch64 port (gmloadernext.aarch64 + the Android arm64 runner) on an x86_64 PC:
# qemu-aarch64 user mode with the arm64 sysroot from tests/pc/make_sysroot.sh, Mesa llvmpipe for
# GLES, on a private Xvfb display at a handheld resolution. Slow (loading takes minutes), so it
# checks behaviour and memory, not speed.
#
# Usage: tests/localtest.sh <port dir> <seconds> <shot times, e.g. "180 400"> [WxH] [tag]
# Output: tests/out/<tag>/ with run.log (timestamped) and shot_<t>.png
set -u
T="$(cd "$(dirname "$0")" && pwd)"
PORT="$(realpath "$1")"; SECS="$2"; SHOTS="$3"; RES="${4:-640x480}"; TAG="${5:-pc}"; D=${DISP:-19}
S="$T/pc/sysroot"; Q="$T/pc/bin/qemu-aarch64-static"
[ -x "$Q" ] || "$T/pc/make_sysroot.sh"
OUT="$T/out/$TAG"; mkdir -p "$OUT"; rm -f "$OUT"/shot_*.png
while [ -e "/tmp/.X$D-lock" ]; do D=$((D + 1)); done
unset WAYLAND_DISPLAY; Xvfb :$D -screen 0 "$RES"x24 -nolisten tcp >/dev/null 2>&1 & XP=$!
for i in $(seq 40); do DISPLAY=:$D xdpyinfo >/dev/null 2>&1 && break; sleep 0.5; done
cd "$PORT"
# Run through ld.so explicitly: exec'ing the binary directly under qemu exits silently.
( DISPLAY=:$D LIBGL_ALWAYS_SOFTWARE=1 SDL_AUDIODRIVER=${SDL_AUDIODRIVER:-dummy} timeout "$SECS" \
    "$Q" -L "$S" "$S/lib/ld-linux-aarch64.so.1" --library-path "$PORT/lib:$S/usr/lib/aarch64-linux-gnu" \
    ./gmloadernext.aarch64 -c gmloader.json 2>&1; echo "EXIT $?" ) \
  | awk '{ print strftime("%H:%M:%S"), $0; fflush() }' > "$OUT/run.log" & GP=$!
p=0; for t in $SHOTS; do sleep $((t - p)); p=$t; DISPLAY=:$D import -window root "$OUT/shot_$t.png" 2>/dev/null; done
wait $GP; kill $XP 2>/dev/null
grep -E "EXIT|Segmentation|Killed|fatal|Failed to load" "$OUT/run.log" | tail -3
ls "$OUT"
