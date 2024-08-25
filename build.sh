#!/bin/bash

# HOME path
export HOME=/home/a/Git/tc
VERSION="$(cat arch/arm64/configs/neptune_defconfig | grep "CONFIG_LOCALVERSION\=" | sed -r 's/.*"(.+)".*/\1/' | sed 's/^.//')"
# Compiler environment
export CLANG_PATH=$HOME/llvm-18.1.0-rc1-x86_64/bin
export PATH="$CLANG_PATH:$PATH"
export CROSS_COMPILE=$HOME/gcc64/bin/aarch64-linux-android-
export CROSS_COMPILE_ARM32=$HOME/gcc32/bin/arm-linux-androideabi-
export CLANG_TRIPLE=aarch64-linux-gnu-
export KBUILD_BUILD_USER=0wnerDied
export KBUILD_BUILD_HOST=Neptune


echo
echo "Setting defconfig"
echo

make CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip neptune_defconfig

echo
echo "Compiling kernel"
echo

make CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip -j$(nproc --all) || exit 1

echo
echo "Building Kernel Image"
echo
find arch/arm64/boot/dts/qcom -name '*.dtb' -exec cat {} + > ./dtb
prebuilts/mkbootimg \
    --kernel arch/arm64/boot/Image.gz \
    --ramdisk prebuilts/ramdisk.gz \
    --cmdline 'androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=2048 firmware_class.path=/vendor/firmware_mnt/image loop.max_part=7 androidboot.usbcontroller=a600000.dwc3 skip_override androidboot.fastboot=1 buildvariant=eng androidboot.selinux=permissive' \
    --base           0x00000000 \
    --pagesize       4096 \
    --kernel_offset  0x00008000 \
    --ramdisk_offset 0x01000000 \
    --second_offset  0x00000000 \
    --tags_offset    0x00000100 \
    --dtb            ./dtb \
    --dtb_offset     0x01f00000 \
    --os_version     '16.1.0' \
    --os_patch_level '2099-12' \
    --header_version 2 \
    -o $VERSION.img

if [[ "${1}" == "upload" ]]; then
    echo
    echo "Uploading"
    echo
    md5sum $imgVERSION.img
    echo
    curl -sL https://git.io/file-transfer | bash -s beta
    ./transfer wet $VERSION.img
fi



