#!/bin/bash
# Builds tests/pc/sysroot (Debian bookworm arm64 libraries: SDL2, Mesa llvmpipe EGL/GLES/GLX)
# and tests/pc/bin/qemu-aarch64-static, without root and without registering binfmt on the host:
# the packages are installed as a foreign architecture inside an amd64 container and copied out.
set -e
T="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$T/sysroot" "$T/bin"
docker run --rm -v "$T/sysroot:/out" -v "$T/bin:/bin-out" debian:bookworm bash -c '
set -e; dpkg --add-architecture arm64; apt-get update -qq
apt-get install -y -qq --no-install-recommends qemu-user-static \
  libsdl2-2.0-0:arm64 libegl1:arm64 libgles2:arm64 libgl1:arm64 libglx-mesa0:arm64 libopengl0:arm64 \
  libgl1-mesa-dri:arm64 libegl-mesa0:arm64 zlib1g:arm64 libstdc++6:arm64 libopenal1:arm64 \
  libx11-6:arm64 libxext6:arm64 libxcursor1:arm64 libxi6:arm64 libxrandr2:arm64 libxss1:arm64 \
  libxkbcommon0:arm64 libudev1:arm64 libasound2:arm64 >/dev/null
cp /usr/bin/qemu-aarch64-static /bin-out/
mkdir -p /out/usr/lib /out/usr/share /out/lib
cp -a /usr/lib/aarch64-linux-gnu /out/usr/lib/
cp -a /usr/share/glvnd /out/usr/share/
ln -sfn ../usr/lib/aarch64-linux-gnu /out/lib/aarch64-linux-gnu
ln -sfn aarch64-linux-gnu/ld-linux-aarch64.so.1 /out/lib/ld-linux-aarch64.so.1
chown -R '"$(id -u):$(id -g)"' /out /bin-out'
echo "sysroot: $(du -sh "$T/sysroot" | cut -f1)"
