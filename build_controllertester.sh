#!/bin/bash

# Build and install sdl2 controller tester
if [ -f "Arkbuild_package_cache/${CHIPSET}/controllertester.tar.gz" ] && [ "$(cat Arkbuild_package_cache/${CHIPSET}/controllertester.commit)" == "$(curl -s https://api.github.com/repos/christianhaitian/SDL2-Controller-Tester/commits/master | jq -r '.sha')" ]; then
    sudo tar -xvzpf Arkbuild_package_cache/${CHIPSET}/controllertester.tar.gz
else
	call_chroot "cd /home/ark &&
	  cd ${CHIPSET}_core_builds &&
	  git clone --recursive --depth=1 https://github.com/christianhaitian/SDL2-Controller-Tester.git &&
	  cd SDL2-Controller-Tester/ &&
	  make -j$(nproc) &&
	  strip controllerTester &&
	  cp controllerTester /usr/local/bin/ &&
	  chmod 777 /usr/local/bin/controllerTester
	  "
	if [ -f "Arkbuild_package_cache/${CHIPSET}/controllertester.tar.gz" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/controllertester.tar.gz
	fi
	if [ -f "Arkbuild_package_cache/${CHIPSET}/controllertester.commit" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/controllertester.commit
	fi
	sudo tar -czpf Arkbuild_package_cache/${CHIPSET}/controllertester.tar.gz Arkbuild/usr/local/bin/controllerTester
	curl -s https://api.github.com/repos/christianhaitian/SDL2-Controller-Tester/commits/master | jq -r '.sha' > Arkbuild_package_cache/${CHIPSET}/controllertester.commit
fi

sudo mkdir -p Arkbuild/opt/system/Advanced/
sudo cp dArkOS_Tools/Advanced/"Controller Tester.sh" Arkbuild/opt/system/Advanced/.
sudo chmod 777 Arkbuild/opt/system/Advanced/"Controller Tester.sh"
call_chroot "chown -R ark:ark /opt"
