#!/bin/bash

# Build and install modified wpa_supplicant with SAE fixes
if [ -f "Arkbuild_package_cache/${CHIPSET}/wpasupplicant.tar.gz" ] && [ "$(cat Arkbuild_package_cache/${CHIPSET}/wpasupplicant.commit)" == "$(curl -s https://raw.githubusercontent.com/christianhaitian/${CHIPSET}_core_builds/refs/heads/master/scripts/wpa_supplicant.sh | grep -oP '(?<=version=").*?(?=")')" ]; then
    sudo tar -xvzpf Arkbuild_package_cache/${CHIPSET}/wpasupplicant.tar.gz
else
	call_chroot "cd /home/ark &&
	  cd ${CHIPSET}_core_builds &&
	  chmod 777 builds-alt.sh &&
	  ./builds-alt.sh wpa_supplicant
	  "
	sudo cp -a Arkbuild/home/ark/${CHIPSET}_core_builds/wpa_supplicant/wpa_passphrase Arkbuild/usr/bin/wpa_passphrase
	sudo cp -a Arkbuild/home/ark/${CHIPSET}_core_builds/wpa_supplicant/wpa_cli Arkbuild/usr/sbin/wpa_cli
	sudo cp -a Arkbuild/home/ark/${CHIPSET}_core_builds/wpa_supplicant/wpa_supplicant Arkbuild/usr/sbin/wpa_supplicant
	sudo chmod 777 Arkbuild/usr/bin/wpa_*
	sudo chmod 777 Arkbuild/usr/sbin/wpa_*
	if [ -f "Arkbuild_package_cache/${CHIPSET}/wpasupplicant.tar.gz" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/wpasupplicant.tar.gz
	fi
	if [ -f "Arkbuild_package_cache/${CHIPSET}/wpasupplicant.commit" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/wpasupplicant.commit
	fi
	sudo tar -czpf Arkbuild_package_cache/${CHIPSET}/wpasupplicant.tar.gz Arkbuild/usr/bin/wpa_passphrase Arkbuild/usr/sbin/wpa_cli Arkbuild/usr/sbin/wpa_supplicant
	curl -s https://raw.githubusercontent.com/christianhaitian/${CHIPSET}_core_builds/refs/heads/master/scripts/wpa_supplicant.sh | grep -oP '(?<=version=").*?(?=")' > Arkbuild_package_cache/${CHIPSET}/wpasupplicant.commit
fi
