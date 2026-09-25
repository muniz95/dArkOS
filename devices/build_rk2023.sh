#!/bin/bash
# Run from the repo root: step scripts, asset dirs and outputs are resolved relative to it
cd "$(dirname "$(readlink -f "$0")")/.."
#exec 3>&1 4>&2
#trap 'exec 2>&4 1>&3' 0 1 2 3
#exec 1>build.log 2>&1
#set -e
if [ -f "build.log" ]; then
  ext=1
  while true
  do
    if [ -f "build.log.${ext}" ]; then
      let ext=ext+1
	  continue
	else
      mv build.log build.log.${ext}
	  break
	fi
  done
fi
(
# Set chipset in environment variable
export CHIPSET=rk3566
export UNIT=rk2023
export UNIT_DTB=${CHIPSET}-${UNIT}

# Load shared utilities (if any)
source ./common/utils.sh

# Let's make sure necessary tools are available
source ./stages/prepare.sh

# Step-by-step build process
source ./stages/setup_partition-rk3566.sh
source ./stages/bootstrap_rootfs-rk3566.sh
source ./stages/build_kernel-rk3566.sh
source ./stages/build_deps.sh
source ./libs/build_sdl2.sh
source ./emulators/build_ppssppsa.sh
source ./emulators/build_ppsspp-2021sa.sh
source ./emulators/build_duckstationsa.sh
source ./emulators/build_mupen64plussa.sh
source ./emulators/build_gzdoom.sh
source ./emulators/build_lzdoom.sh
source ./emulators/build_retroarch.sh
source ./emulators/build_retrorun.sh
source ./emulators/build_yabasanshirosa.sh
source ./emulators/build_mednafen.sh
source ./emulators/build_ecwolfsa.sh
source ./emulators/build_hypseus-singe.sh
source ./emulators/build_openbor.sh
source ./emulators/build_solarus.sh
source ./emulators/build_scummvmsa.sh
source ./emulators/build_fake08.sh
source ./emulators/build_xroar.sh
source ./emulators/build_mvem.sh
source ./emulators/build_bigpemu.sh
source ./tools/build_ogage.sh
source ./tools/build_ogacontrols.sh
source ./tools/build_351files.sh
source ./tools/build_filemanager.sh
source ./tools/build_filebrowser.sh
source ./tools/build_gptokeyb.sh
source ./tools/build_drmtool.sh
source ./tools/build_image-viewer.sh
source ./tools/build_emulationstation-rk3566.sh
source ./emulators/build_linapple.sh
source ./emulators/build_applewinsa.sh
source ./emulators/build_piemu.sh
source ./emulators/build_ti99sim.sh
source ./emulators/build_gametank.sh
source ./emulators/build_openmsxsa.sh
source ./emulators/build_flycastsa.sh
source ./emulators/build_dolphinsa.sh
source ./libs/build_ffmpeg.sh
source ./tools/build_sdljoytest.sh
source ./tools/build_controllertester.sh
source ./tools/build_batteryplus.sh
source ./emulators/build_drastic.sh
source ./emulators/build_dsperate.sh
if [[ "${BUILD_BLUEALSA}" == "y" ]]; then
  source ./libs/build_bluealsa.sh
fi
if [[ "${BUILD_KODI}" == "y" ]]; then
  source ./tools/build_kodi.sh
fi
source ./stages/finishing_touches-rk3566.sh
source ./stages/cleanup_filesystem.sh
source ./stages/write_rootfs-rk3566.sh
source ./stages/clean_mounts.sh
source ./stages/create_image.sh
) 2>&1 | tee -a build.log

echo "rk2023 build completed. Final image is ready."
