#!/bin/bash

# Build and install DinguxCommander
if [ "$UNIT" == "rgb10" ]; then
  BRANCH="master"
  DEVICE_CONFIG="rk3326"
elif [ "$UNIT" == "rg351p" ]; then
  BRANCH="rg351p"
  DEVICE_CONFIG="rg351p"
elif [ "$UNIT" == "rg351mp" ] || [ "$UNIT" == "g350" ] || [ "$UNIT" == "a10mini" ]; then
  BRANCH="rg351mp"
  DEVICE_CONFIG="rg351mp"
elif [ "$UNIT" == "rg351v" ]; then
  BRANCH="rg351mp"
  DEVICE_CONFIG="rg351v"
elif [[ "$UNIT" == *"353"* ]] || [[ "$UNIT" == "rk2023" ]]; then
  BRANCH="rg351mp"
  DEVICE_CONFIG="rk3566"
elif [[ "$UNIT" == *"503"* ]] || [[ "$UNIT" == "rgb30" ]] || [[ "$UNIT" == "rgb20pro" ]] || [[ "$UNIT" == "miniloong" ]]; then
  BRANCH="ogs"
  DEVICE_CONFIG="rk3566"
fi

if [ -f "Arkbuild_package_cache/${CHIPSET}/filemanager_${UNIT}.tar.gz" ] && [ "$(cat Arkbuild_package_cache/${CHIPSET}/filemanager_${UNIT}.commit)" == "$(curl -s https://api.github.com/repos/christianhaitian/rs97-commander-sdl2/commits/${BRANCH} | jq -r '.sha')" ]; then
    sudo tar -xvzpf Arkbuild_package_cache/${CHIPSET}/filemanager_${UNIT}.tar.gz
else
	call_chroot "cd /home/ark &&
	  git clone --recursive https://github.com/christianhaitian/rs97-commander-sdl2.git -b ${BRANCH} &&
	  cd rs97-commander-sdl2 &&
	  if [[ ${UNIT} == \"rgb30\" ]]; then sed -i \"/SCREENW :/c\SCREENW :\= 720\" Makefile &&
	  sed -i \"/SCREENH :/c\SCREENH :\= 720\" Makefile; else echo \"\"; fi &&
	  make -j$(nproc) &&
	  strip DinguxCommander
	  "
	sudo mkdir -p Arkbuild/opt/dingux
	sudo cp Arkbuild/home/ark/rs97-commander-sdl2/DinguxCommander Arkbuild/opt/dingux/
	sudo chmod 777 Arkbuild/opt/dingux/DinguxCommander
	sudo cp -R Arkbuild/home/ark/rs97-commander-sdl2/res/ Arkbuild/opt/dingux/
	sudo rm -rf Arkbuild/home/ark/rs97-commander-sdl2
	if [ -f "Arkbuild_package_cache/${CHIPSET}/filemanager_${UNIT}.tar.gz" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/filemanager_${UNIT}.tar.gz
	fi
	if [ -f "Arkbuild_package_cache/${CHIPSET}/filemanager_${UNIT}.commit" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/filemanager_${UNIT}.commit
	fi
	sudo tar -czpf Arkbuild_package_cache/${CHIPSET}/filemanager_${UNIT}.tar.gz Arkbuild/opt/dingux/
	curl -s https://api.github.com/repos/christianhaitian/rs97-commander-sdl2/commits/${BRANCH} | jq -r '.sha' > Arkbuild_package_cache/${CHIPSET}/filemanager_${UNIT}.commit
fi
if [[ -f "tools/filecommander/configs/oshgamepad.cfg.${DEVICE_CONFIG}" ]]; then
  sudo cp tools/filecommander/configs/oshgamepad.cfg.${DEVICE_CONFIG} Arkbuild/opt/dingux/oshgamepad.cfg
fi
call_chroot "chown -R ark:ark /opt"
