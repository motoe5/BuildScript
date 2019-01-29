#!/bin/bash
BUILDCONFIG="$1"
ARMTYPE="$2"
CORES=$(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}')
VERSION="0.10.1"

echo "Build Script Version: $VERSION"

signing_keys() {
        if [ ! -f "certs/signing_key.pem" ]; then
                echo "Generating new signing keys."
                openssl req -x509 -newkey rsa:4096 -keyout key.pem -out certs/signing_key.pem -days 9999
	fi
}

set_config() {
	make "$BUILDCONFIG" ARCH="$ARMTYPE"
}

compile_kernel() {
	make CROSS_COMPILE=$CROSS_COMPILE EXTRA_CFLAGS=-w ARCH="$ARMTYPE" -j$CORES
}

make_zip() {
	if [ -f "arch/$ARMTYPE/boot/zImage" ]; then
		cp arch/$ARMTYPE/boot/zImage AnyKernel2/
		cd AnyKernel2/ && zip ../lsm-$BUILDCONFIG-anykernel-$ARMTYPE.zip $(ls) -r &>/dev/null
#       	cp drivers/staging/prima/wlan.ko AnyKernel2/modules/vendor/lib/modules/
#       	cp drivers/staging/prima/firmware_bin/* AnyKernel2/modules/vendor/etc/wifi
		echo "Installer zip created @ 'lsm-$BUILDCONFIG-anykernel-$ARMTYPE.zip'!"
	fi
}

if [ "$2" == "arm64" ]; then
	ARMTYPE="arm64"
	CROSS_COMPILE="gcc-linaro-7.4.1/bin/aarch64-linux-gnu-"
	else
	ARMTYPE="arm"
	CROSS_COMPILE="gcc-linaro-7.1.1/bin/arm-linux-gnueabihf-"
fi

if [ "$1" != "" ]; then
	BUILDCONFIG="$1"
	else
	echo "Listing available 32 Bit Configs:"
	ls arch/arm/configs/
	echo
	echo "Listing available 64 Bit Configs:"
	ls arch/arm64/configs/
	echo
	echo "Type Configuration Name: "
	read BUILDCONFIG
fi

if [ -f "arch/$ARMTYPE/configs/$BUILDCONFIG" ]; then
	echo "This is a $CORES system. Using -j$CORES"
	echo "Building LSM for $BUILDCONFIG-$ARMTYPE ..."
	sleep 3
	signing_keys
	set_config
	compile_kernel
	make_zip
fi
