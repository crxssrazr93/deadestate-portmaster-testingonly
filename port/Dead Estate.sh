#!/bin/bash
# PORTMASTER: deadestate.zip, Dead Estate.sh

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR="/$directory/ports/deadestate"
cd "$GAMEDIR"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

export LD_LIBRARY_PATH="$GAMEDIR/lib:$LD_LIBRARY_PATH"
$ESUDO chmod +x "$GAMEDIR/gmloadernext.aarch64"
$ESUDO chmod +x "$GAMEDIR/tools/gmtoolkit.${DEVICE_ARCH}"

# First start (or new game files in assets/): patch them on the PortMaster patcher screen.
if [ ! -f "$GAMEDIR/patchlog.txt" ] || [ -f "$GAMEDIR/assets/data.win" ]; then
  if [ -f "$controlfolder/utils/patcher.txt" ]; then
    export PATCHER_FILE="$GAMEDIR/tools/patchscript"
    export PATCHER_GAME="$(basename "${0%.*}")"
    export PATCHER_TIME="about 20 minutes"
    export controlfolder ESUDO DEVICE_RAM DEVICE_ARCH
    source "$controlfolder/utils/patcher.txt"
    $ESUDO kill -9 $(pidof gptokeyb) 2>/dev/null
  else
    pm_message "This port requires the latest version of PortMaster."
    exit 1
  fi
fi
[ -f "$GAMEDIR/patchlog.txt" ] || { pm_message "Patching did not finish. See ports/deadestate/patcherr.txt."; exit 1; }

# The game reads the pad itself (twin stick); gptokeyb only handles the hotkey exit.
$GPTOKEYB "gmloadernext.aarch64" &
pm_platform_helper "$GAMEDIR/gmloadernext.aarch64" >/dev/null
./gmloadernext.aarch64 -c "$GAMEDIR/gmloader.json"

pm_finish
