#!/bin/bash

kernel=$(uname -a|awk '{ print $2 }')

if [ $kernel != "archlinux" ]; then

# ディスクイメージを作成するために必要なツールをインストール
sudo apt-get update && sudo apt-get -y install  build-essential gcc-aarch64-linux-gnu bison \
qemu-user-binfmt qemu-system-arm qemu-efi-aarch64 binfmt-support \
debootstrap flex libssl-dev bc rsync kmod cpio xz-utils fakeroot parted \
udev dosfstools uuid-runtime git-lfs device-tree-compiler python3 \
python-is-python3 fdisk bc debhelper python3-pyelftools python3-setuptools \
python3-pkg-resources swig libfdt-dev libpython3-dev gawk \
git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex \
libelf-dev bison libgnutls28-dev libdw-dev
else
sudo pacman -S --noconfirm --need base-devel uboot-tools dtc bc gcc flex bison git wget python-setuptools python-pkg_resources python swig python-pyelftools
fi

	rm -rf arm64
	mkdir arm64
mem_size=`free --giga|grep Mem|awk '{print $2}'`
if [ $mem_size -gt 2 ]; then
        sudo mount -t tmpfs -o size=1G tmpfs arm64
fi
	cd arm64

		git clone --depth 1 https://github.com/rockchip-linux/rkbin
		
		DDR=`ls rkbin/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v*.bin`
		BL31=`ls rkbin/bin/rk35/rk3588_bl31*.elf`
	export BL31=`pwd`/$BL31
	export ROCKCHIP_TPL=`pwd`/$DDR
echo ""
echo "export ROCKCHIP_TPL=$ROCKCHIP_TPL"
echo "export BL31=$BL31"
echo ""
		export PATH=`pwd`/tools/binman:$PATH
echo ""
echo "PATH=$PATH"
echo ""

		git clone --depth 1 https://gitlab.com/u-boot/u-boot.git -b v2025.07
		cd u-boot
		if [ ! -f configs/$1 ]; then
			echo "$1 not found in configs"
			cd ..
			exit 1
		fi

	echo 'CONFIG_SYS_SOC="rk3588"' >> configs/$1
sed -i 's/#ifndef CONFIG_XPL_BUILD/#ifndef CONFIG_XPL_BUILD\n\n #define BOOT_TARGETS    "nvme scsi mmc"\n\n/' include/configs/rockchip-common.h

                make clean $1
                
#fix(build): fix pylibfdt build error with modern Python3/SWIG environments

#- Replace legacy Python 2 APIs (PyString/PyInt) in libfdt.i_shipped with Python 3 versions
#- Remove pre-generated libfdt_wrap.c to force regeneration

                # ↓★ここから3行を追加・変更します
                sed -i 's/PyString_FromString/PyUnicode_FromString/g' scripts/dtc/pylibfdt/libfdt.i_shipped
                sed -i 's/PyInt_AsLong/PyLong_AsLong/g' scripts/dtc/pylibfdt/libfdt.i_shipped
                rm -f scripts/dtc/pylibfdt/libfdt_wrap.c
                
		make -j8
		cp u-boot-rockchip.bin ../..
	echo "dd if=u-boot-rockchip.bin of=/dev/sdX seek=1 bs=32k conv=fsync"
	cd ../..
echo "DISK usage"
df arm64
if [ $mem_size -gt 2 ]; then
        sudo umount arm64
	sleep 2
fi 
rm -rf arm64
exit 0

