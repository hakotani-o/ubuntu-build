#!/bin/bash

set -eE
trap 'echo Error: in $0 on line $LINENO' ERR

if [ $# -ne 1 ]; then
	echo "$0 linux_dir"
	exit 1
fi

# ディスクイメージを作成するために必要なツールをインストール
sudo apt-get update && sudo apt-get -y install  build-essential gcc-aarch64-linux-gnu bison \
qemu-user-binfmt qemu-system-arm qemu-efi-aarch64 binfmt-support \
debootstrap flex libssl-dev bc rsync kmod cpio xz-utils fakeroot parted \
udev dosfstools uuid-runtime git-lfs device-tree-compiler python3 \
python-is-python3 fdisk bc debhelper python3-pyelftools python3-setuptools \
python3-pkg-resources swig libfdt-dev libpython3-dev gawk \
git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex \
libelf-dev bison libgnutls28-dev libdw-dev wget

linux_dir=$1

rm -rf $linux_dir && mkdir $linux_dir
mem_size=`free --giga|grep Mem|awk '{print $2}'`
if [ $mem_size -gt 8 ]; then
	sudo mount -t tmpfs -o size=8G tmpfs $linux_dir
fi

cd $linux_dir
#git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git -b linux-7.1.y
#git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git -b v7.0.10
 git clone --depth 1 https://github.com/torvalds/linux.git -b v7.2-rc7

mkdir minimyth2 && cd minimyth2
# 3559-media-rkvdec-fix-PM-runtime-teardown-ordering-in-remove.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3559-media-rkvdec-fix-PM-runtime-teardown-ordering-in-remove.patch
# 3569-media-rkvdec-prime-VDPU383-deblock-warmup-rk3576.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3569-media-rkvdec-prime-VDPU383-deblock-warmup-rk3576.patch
# 3570-media-rkvdec-add-VP9-VDPU381-decoder-support.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3570-media-rkvdec-add-VP9-VDPU381-decoder-support.patch
# 3571-media-rkvdec-vp9-fix-altref-vscale-and-segmap-size-for-2K-decode.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3571-media-rkvdec-vp9-fix-altref-vscale-and-segmap-size-for-2K-decode.patch
# 3572-media-rkvdec-vdpu381-add-VP9-profile-2-10bit-support.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3572-media-rkvdec-vdpu381-add-VP9-profile-2-10bit-support.patch
# 3573-media-rkvdec-vdpu381-vp9-use-the-real-buffer-stride.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3573-media-rkvdec-vdpu381-vp9-use-the-real-buffer-stride.patch
# 3574-media-rkvdec-Add-support-for-the-VDPU346-variant.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3574-media-rkvdec-Add-support-for-the-VDPU346-variant.patch
cd ..

cd linux

# minimyth2 patch
for i in ../minimyth2/*.patch
do
        echo $i
        patch -p1 < $i
done

wget https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/refs/heads/master/core/linux-aarch64/config
sed -i  '/^CONFIG_INITRAMFS_SOURCE/d' config
#make defconfig

./scripts/kconfig/merge_config.sh -m config ../../my-add.txt

./scripts/config --set-val DEBUG_INFO_NONE y
./scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
./scripts/config --disable DEBUG_INFO_DWARF4
./scripts/config --disable DEBUG_INFO_DWARF5

make olddefconfig
 sed -i 's/CONFIG_LOCALVERSION="-ARCH"/CONFIG_LOCALVERSION=""/' .config

fakeroot make -j$(nproc) LOCALVERSION="-rockchip" deb-pkg
tmp_var=$(make LOCALVERSION="-rockchip" -s kernelrelease)
echo "tmp_var=$tmp_var" > ../../tmp_var.txt

# Exit trap is no longer needed
trap '' EXIT
cd ..
cp *.deb ..
cd ..
echo "DISK usage"
df $1
if [ $mem_size -gt 4 ]; then
	sudo umount $linux_dir
	sleep 2
fi
exit 0
