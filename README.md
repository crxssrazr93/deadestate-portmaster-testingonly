# Dead Estate (Demo) for PortMaster: testing only

Work in progress towards a [PortMaster](https://portmaster.games/) port of the [Dead Estate](https://store.steampowered.com/app/1484720/Dead_Estate/) demo (Cute Bunny Games, 2021), a twin stick roguelite shooter, for aarch64 Linux handhelds. This repository is a test bed, not a release: the port packages and patches itself on the device, but it has not been play tested.

No game files are included. You supply the demo from your own Steam library.

| | |
|--|--|
| Status | A port built by `build/assemble.sh` boots on an Anbernic RG35XX H (Knulli, Mali G31, 1 GB) through EmulationStation to the title screen and attract mode, and the game finds the device's controls as a gamepad ("Xbox 360 Controller" at slot 0). Gameplay, sound and frame rate are not tested yet. |
| Memory | 243 to 260 MB peak resident after two minutes, about 550 MB still available (the unmodified game was killed by the OOM killer at 670 MB). |
| Patcher | Tested on the device from a clean install of `build/package.sh` output: PortMaster's patcher screen runs `tools/patchscript` (gmtoolkit on the device) in about 18 minutes on the H700, then the game starts. |
| Route | gmloader-next (a pre 2026-04-24 build) with the GameMaker 2.3.7 Android arm64 runner, after a gmtoolkit pass (ASTC textures, compressed audio, GMLive patched out). |
| Game | Steam app 1529790, depot 1529791 (Windows), build 7634959. GameMaker VM build, bytecode 17, runtime 2.3.6.464, 480x270. |

## Getting the game

```
steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir <dir> +login <user> +app_update 1529790 validate +quit
```

The folder needs `data.win`, `audiogroup1.dat` and `audiogroup2.dat`.

## Layout

* `port/`: what will ship. `Dead Estate.sh` (launcher with the patcher step), `deadestate/tools/patchscript` (first start patching on the device), `deadestate/gmloader.json`, `deadestate/tools/gmtoolkit.json` (texture, audio and code patch config) and `deadestate/tools/gml/` (GML replacements).
* `build/fetch_deps.sh`: downloads the loader, its shim libraries, the 2.3.7 runner and gmtoolkit, pinned to commits and checked by MD5.
* `build/package.sh`: makes `dist/deadestate.zip`, the folder a player installs (runner in `deadestate.port`, gmtoolkit for aarch64, no game files).
* `build/assemble.sh <game folder> <out dir>`: builds an already patched port folder on a PC (gmtoolkit runs in a Docker container that has vorbis-tools).
* `tests/localtest.sh`: runs that port folder on an x86_64 PC (see below).
* `tests/device/knulli.sh`, `knulli_shot.sh` and `devpad.py`: run a command on the test device, grab its screen, and press its buttons.
* `docs/PORTING.md`: findings, the route that works, and every route that failed with the reason.

## Testing on a PC

gmloader-next only builds for ARM, so the PC test runs the real aarch64 port: `qemu-aarch64` in user mode with a Debian arm64 sysroot (SDL2, Mesa llvmpipe for GLES, GLX), on a private Xvfb display at 640x480. `tests/pc/make_sysroot.sh` builds the sysroot inside an amd64 container, so it needs Docker but no root and no binfmt registration on the host.

```
build/assemble.sh ~/steam/deadestate-demo tests/out/port
tests/localtest.sh tests/out/port 900 "180 400 650" 640x480 pc
```

It is slow (the game takes minutes to reach its first screen) and says nothing about speed, but it reproduces the same loader and runner behaviour as the device: the crashes in `docs/PORTING.md` happened at the same place on both.

## Testing on the device

The device is a Knulli handheld reachable over SSH (`KNULLI_HOST`, default `knulli`; password in `~/.ssh/knulli.pass`). Copy the assembled folder to `/userdata/roms/ports/deadestate/` and `port/Dead Estate.sh` to `/userdata/roms/ports/`, then start it through EmulationStation's API so it runs exactly as a player would start it:

```
tests/device/knulli.sh 'curl -s http://127.0.0.1:1234/reloadgames'
tests/device/knulli.sh "curl -s -X POST -d '/userdata/roms/ports/Dead Estate.sh' http://127.0.0.1:1234/launch"
tests/device/knulli_shot.sh shot.png
```

The game writes its log to `/userdata/roms/ports/deadestate/log.txt`.

To test the patcher, unzip `dist/deadestate.zip` into `/userdata/roms/ports/`, copy the three game files into `deadestate/assets/` and launch as above. The patcher screen waits for a button press before it starts and again when it ends; press A on the device with `devpad.py` (copy it to `/tmp` first):

```
tests/device/knulli.sh 'cat > /tmp/devpad.py' < tests/device/devpad.py
tests/device/knulli.sh 'python3 /tmp/devpad.py "press A; wait 2; press A; wait 2; press A"'
```

Its log is `deadestate/patchlog.txt` (`patcherr.txt` on failure). The game starts in keyboard mode and switches to the gamepad a few seconds later ("gamepad detected @ slot 0" in the log).

## Findings

* **Loader:** gmloader-next commit 5c1df13 (2026-04-24) loads every library a runner depends on and fails on a missing one. All GameMaker 2.3.x Android runners need `liboboe.so`, which needs `libOpenSLES.so`, which the loader does not provide. Builds from before that commit skip it and run the 2.3.7 runner fine. A 2022 runner (no oboe) segfaults while loading this game's data.
* **Memory:** 67 texture pages (30 at 2048x2048) as inline PNG plus 105 MB of audio groups overflow 1 GB. gmtoolkit with ASTC 6x6 and 64 kbps audio takes the data file from 67 MB to 23 MB, the audio groups from 105 MB to 35 MB, and the textures to 55 MB of compressed PVR files.
* **GMLive:** the shipped build still runs a live coding tool that indexes all assets at start and polls `http://localhost:5100` every second. A one event GML patch turns it off.
* **Input:** the game has native gamepad support (left stick moves, right stick aims, RT fires) and reported "Set controls to gamepad" on the device. Any keyboard or mouse event switches it back to keyboard and mouse, so gptokeyb must not send keys.
* **Screen:** the game draws at 480x270 through three shader surfaces and is letterboxed to 640x360 on a 640x480 screen.

## To do

1. Play test on the device: movement, aiming, firing, menus, pause, the hotkey exit; check gptokeyb sends no keys.
2. Measure frame rate in a busy room (target 60 fps on the bytecode interpreter). Check film grain and the static shader cost.
3. Check the shaders on Mali: `shSwap` palette swap precision (mediump banding) and `sh_outline` loops with non constant bounds.
4. Decide whether palette keyed pages must stay inline (`keep_inline_colors`) so ASTC does not shift the key colours.
5. Window logic: `window_set_fullscreen` is called every frame when the setting differs, and the scale is clamped to `display_get_height() div 270`.
6. Steam: `steam_is_screenshot_requested` and `steam_is_overlay_activated` run unguarded every frame (the loader stubs them, confirm no log spam or cost).
7. Scripted virtual pad for `tests/localtest.sh` (the device has `devpad.py`; the PC run has no pad, so the game stays in keyboard mode).
8. `port.json`, `README.md` for players, `gameinfo.xml`, cover and screenshot.
9. Test on muOS and on a 2 GB device; decide a 4x4 ASTC config for devices with more RAM.

## License

The port's own files are MIT (see `LICENSE`). The game, the GameMaker runner, gmloader-next and gmtoolkit keep their own licenses; none of them are in this repository.
