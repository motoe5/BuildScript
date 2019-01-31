#!/bin/bash
SCRIPT_VERSION=0.10.2
TARGET_CONFIG="$1"
TARGET_ARCH="$2"
EXTRA_CFLAGS=-w
HOST_ARCH=$(arch)
HOST_CORES=3
#HOST_CORES=$($(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}')- 1)
echo "Build Script Version: $SCRIPT_VERSION"
echo "created by t3zz and f1A5h"

# Core Functions
usage() {
	echo "usage: ./make.sh <config> <arm|arm64>"
}

check_signing_keys() {
        if [ ! -f "certs/signing_key.pem" ]; then
                echo "Generating new signing keys."
                openssl req -x509 -newkey rsa:4096 -keyout key.pem -out certs/signing_key.pem -days 9999
	fi
}

input_target_config() {
	echo
	echo -n "Type Configuration Name: "
	read TARGET_CONFIG
}

set_target_config() {
	make "$TARGET_CONFIG" ARCH="$TARGET_ARCH"
}

compile_kernel() {
	make CROSS_COMPILE=$CROSS_COMPILE EXTRA_CFLAGS=$EXTRA_CFLAGS ARCH="$TARGET_ARCH" # -j$CORES
}

make_zip() {
	if [ -f "arch/$TARGET_ARCH/boot/zImage" ]; then
		if [ $TARGET_ARCH = 'arm' ];then
		cp arch/$TARGET_ARCH/boot/zImage AnyKernel2/zImage
		fi
		if [ $TARGET_ARCH = 'arm64' ];then
		cp arch/$TARGET_ARCH/boot/Image.gz AnyKernel2/zImage
		fi
		cd AnyKernel2/ && zip ../lsm-$TARGET_CONFIG-anykernel-$TARGET_ARCH.zip $(ls) -r &>/dev/null
#       	cp drivers/staging/prima/wlan.ko AnyKernel2/modules/vendor/lib/modules/
#       	cp drivers/staging/prima/firmware_bin/* AnyKernel2/modules/vendor/etc/wifi
		echo "Installer zip created @ 'lsm-$TARGET_CONFIG-anykernel-$TARGET_ARCH.zip'!"
	fi
}

prepare_build() {
	if [ -f "arch/$TARGET_ARCH/configs/$TARGET_CONFIG" ]; then
		echo "This is a $HOST_CORES core $ARCH system. Building kernel with -j$HOST_CORES"
		echo "Building LSM for $TARGET_CONFIG-$TARGET_ARCH"
		sleep 3
		run_build
	else
		echo "This config isn't supported with the specified arch: $TARGET_ARCH"
		echo "Please try again with a proper defconfig"
	fi
}

run_build() {
	check_signing_keys
	set_target_config
	compile_kernel
	make_zip
}

if [ "$1" != "" ]; then
	TARGET_CONFIG="$1"
	else
	usage
	if [ -d arch/arm/configs ];then
		echo
		echo "Listing available 32 Bit Configs:"
		ls arch/arm/configs/
	fi
	if [ -d arch/arm/configs ];then
		echo
		echo "Listing available 64 Bit Configs:"
		ls arch/arm64/configs/
	fi
	# input_target_config
fi

if [ "$2" = "arm64" ]; then
	TARGET_ARCH="arm64"
	CROSS_COMPILE="gcc-linaro-7.4.1/bin/aarch64-linux-gnu-"
	else
	TARGET_ARCH="arm"
	CROSS_COMPILE="gcc-linaro-7.1.1/bin/arm-linux-gnueabihf-"
fi

if [ -f ".dir" ]; then
	echo "This script cannot be ran from this dir!"
	echo "Please symlink this file into kernel source dir:"
	echo "ln -s make.sh <kernel dir>"
else
	prepare_build
fi
