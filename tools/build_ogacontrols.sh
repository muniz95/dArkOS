#!/bin/bash

# Build and install oga_controls for various dArkOS menus from christianhaitian/oga_controls
if [ -f "Arkbuild_package_cache/${CHIPSET}/ogacontrols_${UNIT}.tar.gz" ] && [ "$(cat Arkbuild_package_cache/${CHIPSET}/ogacontrols_${UNIT}.commit)" == "$(curl -s https://api.github.com/repos/christianhaitian/oga_controls/commits/quitter | jq -r '.sha')" ]; then
    sudo mkdir -p Arkbuild/opt/quitter
    sudo tar -xvzpf Arkbuild_package_cache/${CHIPSET}/ogacontrols_${UNIT}.tar.gz
    call_chroot "chown -R ark:ark /opt/quitter"
else
	call_chroot "cd /home/ark &&
	  git clone --recursive --depth=1 https://github.com/christianhaitian/oga_controls.git -b quitter &&
	  cd oga_controls &&
	  if [ ${UNIT} == \"miniloong\" ]; then sed -i \"/back_key \= 314/s//back_key \= 316/g\" main.c; fi &&
	  make all &&
	  mkdir -p /opt/quitter &&
	  strip oga_controls &&
	  cp oga_controls /opt/quitter/ &&
	  chmod 777 /opt/quitter/oga_controls &&
	  chown -R ark:ark /opt/quitter
	  "
	sudo rm -rf Arkbuild/home/ark/oga_controls
	if [ -f "Arkbuild_package_cache/${CHIPSET}/ogacontrols_${UNIT}.tar.gz" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/ogacontrols_${UNIT}.tar.gz
	fi
	if [ -f "Arkbuild_package_cache/${CHIPSET}/ogacontrols_${UNIT}.commit" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/ogacontrols_${UNIT}.commit
	fi
	sudo tar -czpf Arkbuild_package_cache/${CHIPSET}/ogacontrols_${UNIT}.tar.gz Arkbuild/opt/quitter/oga_controls
	curl -s https://api.github.com/repos/christianhaitian/oga_controls/commits/quitter | jq -r '.sha' > Arkbuild_package_cache/${CHIPSET}/ogacontrols_${UNIT}.commit
fi
