# Porting notes

## The game

Dead Estate Demo, Steam app 1529790, depot 1529791 (Windows only), build 7634959 (Nov 2021).
GameMaker VM build (not YYC), bytecode 17. The game's own GMLive code records the runtime as 2.3.6.464.
Native resolution 480x270. No extensions (EXTN is empty), so Steam is built into the runner.
`data.win` 67 MB (TXTR 32 MB in 67 PNG pages, 30 of them 2048x2048), `audiogroup1.dat` 82 MB (music, OGG 192 kbps), `audiogroup2.dat` 23 MB (effects, mostly WAV).

## Route that works

gmloader-next built before commit 5c1df13 (2026-04-24) with the GameMaker 2.3.7 Android arm64 runner, after a gmtoolkit pass:

* Loader: the `gmloadernext.aarch64` shipped by Hostile Lands and Hotline Sanzu (md5 `0d2f4880314bcaebe4e0fefa6f058adf`).
* Runner: `libyoyo.so` and `libc++_shared.so` from the `2.3.7 - 17.apk` wrapper (Fraxinus88/GMloader-ports). Same file as Chicory's runner.
* gmtoolkit (`port/deadestate/tools/gmtoolkit.json`): ASTC 6x6 textures to `saves/textures`, audio to 64 kbps OGG, GMLive patched out. Result: game.droid 23 MB, audio groups 27 MB and 8.3 MB, textures 55 MB.

Measured on an RG35XX H (Knulli): reaches character select, 260 MB RSS after 2 minutes, 540 MB still available.

## What failed and why

| Attempt | Result | Cause |
|--|--|--|
| Current gmloader-next (Picayune's build, md5 `3c721c06`) + 2.3.7 runner | `Failed to load module 'liboboe.so'`, then `libOpenSLES.so` | Commit 5c1df13 made the loader load every DT_NEEDED library recursively and fail on any missing one. All 2.3.x runners need liboboe, which needs OpenSLES, which the loader does not provide. Older builds skipped missing dependencies. |
| Current gmloader-next + 2022.0.3.98 LTS runner (no oboe) | Segfault while loading data, after the FONT chunk (device and PC alike) | Runner newer than the data format. Do not use 2022 runners for this game. |
| Pre-refactor loader + 2.3.7 runner, unmodified data | Runs game code, then killed by the OOM killer at about 110 s (RSS 670 MB) | Inline PNG pages decoded to RGBA plus 105 MB of audio groups. Fixed by the gmtoolkit pass. |
| Chicory's loader build (`23bf3068`) | Needs `libavcodec.so.58` | Older ffmpeg linked build. Not used. |

## Game specific findings (decompiled with UndertaleModTool CLI 0.9.2.0)

* `obj_gmlive` in the first room calls `live_init` (indexes every asset) and polls `http://localhost:5100` every second. Patched: its Create event sets `global.live_request_guid` to undefined and destroys itself, so the 389 `live_call()` checks in game code return early.
* Native gamepad support (twin stick). `game.manageController` switches to keyboard and mouse on any key or mouse event, so gptokeyb must not send keys. The log shows "Set controls to gamepad" on the device.
* Renders 480x270 through three surfaces with shaders, letterboxed to 640x360 on a 640x480 screen.
* Only `settings.sav` is written (`ds_map_secure_save`).

## On device patching

Measured on the RG35XX H from a clean install of `build/package.sh` output: gmtoolkit (aarch64, 2 threads, CPU capped at 80%) compresses audio in about 15 minutes (110.7 MB to 32.6 MB) and the 67 textures in about 3, about 18 minutes in all. The result matches the PC build to within the zip metadata. The PortMaster patcher screen needs a button press before it starts and when it ends.
