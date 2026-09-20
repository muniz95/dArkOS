#!/bin/bash

# Build and install gptokeyb for various dArkOS menus from christianhaitian/gptokeyb
if [ -f "Arkbuild_package_cache/${CHIPSET}/gptokeyb.tar.gz" ] && [ "$(cat Arkbuild_package_cache/${CHIPSET}/gptokeyb.commit)" == "$(curl -s https://api.github.com/repos/christianhaitian/gptokeyb/commits/inttools | jq -r '.sha')" ]; then
    sudo mkdir -p Arkbuild/opt/inttools
    sudo tar -xvzpf Arkbuild_package_cache/${CHIPSET}/gptokeyb.tar.gz
else
	call_chroot "cd /home/ark &&
	  git clone --recursive --depth=1 https://github.com/christianhaitian/gptokeyb.git -b inttools &&
	  cd gptokeyb &&
	  make all &&
	  mkdir -p /opt/inttools &&
	  strip gptokeyb &&
	  cp gptokeyb /opt/inttools/ &&
	  chmod 777 /opt/inttools/gptokeyb
	  "
	sudo rm -rf Arkbuild/home/ark/gptokeyb
	if [ -f "Arkbuild_package_cache/${CHIPSET}/gptokeyb.tar.gz" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/gptokeyb.tar.gz
	fi
	if [ -f "Arkbuild_package_cache/${CHIPSET}/gptokeyb.commit" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/gptokeyb.commit
	fi
	sudo tar -czpf Arkbuild_package_cache/${CHIPSET}/gptokeyb.tar.gz Arkbuild/opt/inttools/gptokeyb
	curl -s https://api.github.com/repos/christianhaitian/gptokeyb/commits/inttools | jq -r '.sha' > Arkbuild_package_cache/${CHIPSET}/gptokeyb.commit
fi
sudo cp inttools/* Arkbuild/opt/inttools/
call_chroot "chown -R ark:ark /opt/inttools"
sudo chmod 777 Arkbuild/opt/inttools/osk.py

# Copy some other tools that make use of gptokeyb
sudo cp scripts/osk Arkbuild/usr/bin/
sudo cp scripts/msgbox Arkbuild/usr/bin/
sudo chmod 777 Arkbuild/usr/bin/osk
sudo chmod 777 Arkbuild/usr/bin/msgbox
