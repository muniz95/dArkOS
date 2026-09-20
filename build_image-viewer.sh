#!/bin/bash

# Build and install image-viewer
if [ -f "Arkbuild_package_cache/${CHIPSET}/image-viewer.tar.gz" ] && [ "$(cat Arkbuild_package_cache/${CHIPSET}/image-viewer.commit)" == "$(curl -s https://api.github.com/repos/JohnIrvine1433/ThemeMaster-Image_Viewer/commits/master | jq -r '.sha')" ]; then
    sudo tar -xvzpf Arkbuild_package_cache/${CHIPSET}/image-viewer.tar.gz
else
	call_chroot "cd /home/ark &&
	  git clone --recursive https://github.com/JohnIrvine1433/ThemeMaster-Image_Viewer.git &&
	  cd ThemeMaster-Image_Viewer &&
	  make &&
	  strip image-viewer &&
	  cp image-viewer /usr/local/bin/ &&
	  chmod 777 /usr/local/bin/image-viewer
	  "
	sudo rm -rf Arkbuild/home/ark/ThemeMaster-Image_Viewer
	if [ -f "Arkbuild_package_cache/${CHIPSET}/image-viewer.tar.gz" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/image-viewer.tar.gz
	fi
	if [ -f "Arkbuild_package_cache/${CHIPSET}/image-viewer.commit" ]; then
	  sudo rm -f Arkbuild_package_cache/${CHIPSET}/image-viewer.commit
	fi
	sudo tar -czpf Arkbuild_package_cache/${CHIPSET}/image-viewer.tar.gz Arkbuild/usr/local/bin/image-viewer
	curl -s https://api.github.com/repos/JohnIrvine1433/ThemeMaster-Image_Viewer/commits/master | jq -r '.sha' > Arkbuild_package_cache/${CHIPSET}/image-viewer.commit
fi
