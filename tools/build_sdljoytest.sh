#!/bin/bash

# Build and install sdljoytest from EmuElec
if [ -f "Arkbuild_package_cache/${CHIPSET}/sdljoytest.tar.gz" ] && [ "$(cat Arkbuild_package_cache/${CHIPSET}/sdljoytest.commit)" == "$(curl -s https://api.github.com/repos/christianhaitian/sdljoytest/commits/master | jq -r '.sha')" ]; then
    sudo tar -xvzpf Arkbuild_package_cache/${CHIPSET}/sdljoytest.tar.gz
else
	call_chroot "cd /home/ark &&
	  cd ${CHIPSET}_core_builds &&
	  git clone --recursive --depth=1 https://github.com/christianhaitian/sdljoytest.git &&
	  cd sdljoytest/ &&
	  make -j$(nproc) &&
	  strip gamepad_info map_gamepad_SDL2 test_gamepad_SDL2 &&
	  cp gamepad_info /usr/local/bin/sdljoyinfo &&
	  cp map_gamepad_SDL2 /usr/local/bin/sdljoymap &&
	  cp test_gamepad_SDL2 /usr/local/bin/sdljoytest &&
	  chmod 777 /usr/local/bin/{sdljoyinfo,sdljoymap,sdljoytest}
	  "
	if [ -f "Arkbuild_package_cache/${CHIPSET}/sdljoytest.tar.gz" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/sdljoytest.tar.gz
	fi
	if [ -f "Arkbuild_package_cache/${CHIPSET}/sdljoytest.commit" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/sdljoytest.commit
	fi
	sudo tar -czpf Arkbuild_package_cache/${CHIPSET}/sdljoytest.tar.gz Arkbuild/usr/local/bin/sdljoyinfo Arkbuild/usr/local/bin/sdljoymap Arkbuild/usr/local/bin/sdljoytest
	curl -s https://api.github.com/repos/christianhaitian/sdljoytest/commits/master | jq -r '.sha' > Arkbuild_package_cache/${CHIPSET}/sdljoytest.commit
fi
