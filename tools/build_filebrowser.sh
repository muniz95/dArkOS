#!/bin/bash

fbver=$(curl --silent -qI https://github.com/filebrowser/filebrowser/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}')
if [ -f "Arkbuild_package_cache/${CHIPSET}/filebrowser.tar.gz" ] && [ "$(cat Arkbuild_package_cache/${CHIPSET}/filebrowser.commit)" == "${fbver}" ]; then
    sudo tar -xvzpf Arkbuild_package_cache/${CHIPSET}/filebrowser.tar.gz
else
	wget -t 3 -T 60 --no-check-certificate https://github.com/filebrowser/filebrowser/releases/download/${fbver}/linux-arm64-filebrowser.tar.gz
	sudo mkdir -p Arkbuild/usr/local/bin
	sudo tar -xvzf linux-arm64-filebrowser.tar.gz -C Arkbuild/usr/local/bin filebrowser
	sudo chmod 777 Arkbuild/usr/local/bin/filebrowser
	rm -f linux-arm64-filebrowser.tar.gz
	if [ -f "Arkbuild_package_cache/${CHIPSET}/filebrowser.tar.gz" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/filebrowser.tar.gz
	fi
	if [ -f "Arkbuild_package_cache/${CHIPSET}/filebrowser.commit" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/filebrowser.commit
	fi
	sudo tar -czpf Arkbuild_package_cache/${CHIPSET}/filebrowser.tar.gz Arkbuild/usr/local/bin/filebrowser
	echo "${fbver}" > Arkbuild_package_cache/${CHIPSET}/filebrowser.commit
fi
sudo cp tools/filebrowser/filebrowser.db Arkbuild/home/ark/.config/
call_chroot "chown -R ark:ark /home/ark/.config/filebrowser.db"
