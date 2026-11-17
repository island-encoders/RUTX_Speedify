#!/bin/bash
# Use a fresh official 7.26.2 SDK. No firmware image is flashed by this script.
set -e
SDK=${1:?Usage: build-baseline.sh SDK_ROOT STOCK_TUN_KO COMPARISON_JSON}
STOCK_TUN=${2:?}
COMPARISON=${3:?}
PORT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$SDK/init-build-env"
export LC_ALL=C ARCH=arm CROSS_COMPILE=arm-poky-linux-musleabi-
cd "$SDK/assets/kernel-src"
if [ ! -f .baseline-complete ]; then
    [ ! -f net/netfilter/sfy_udp_lookup.c ] || { echo 'Use a fresh SDK for the stock baseline'; exit 1; }
    cp ../kernel_defconfig .config
    make olddefconfig
    make -j6 vmlinux modules
    cp .config .config.stock-baseline
    cp Module.symvers Module.symvers.stock-baseline
    touch .baseline-complete
fi
python3 "$PORT_ROOT/compare_elf_sections.py" "$STOCK_TUN" drivers/net/tun.ko >"$COMPARISON"
echo 'Stock module executable-section comparison passed.'
