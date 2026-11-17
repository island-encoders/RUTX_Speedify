#!/bin/bash
# Build native musl iptables plugins using the same RutOS SDK as the router.
set -e
SDK=${1:?Usage: build-native-plugins.sh SDK_ROOT IPTABLES_TAR_XZ OUTPUT_DIR}
SOURCE=${2:?}
OUTPUT=${3:?}
PORT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$SDK/init-build-env"
export LC_ALL=C
mkdir -p "$SDK/speedify-iptables-src" "$OUTPUT"
tar -xJf "$SOURCE" -C "$SDK/speedify-iptables-src" --strip-components=1
cd "$SDK/speedify-iptables-src"
for plugin in TPROXY addrtype socket owner pkttype quota; do
    $CC -fPIC -shared -nostartfiles -Werror=implicit-function-declaration -Wl,--no-undefined -DXTABLES_INTERNAL -D_INIT="libxt_${plugin}_init" -o "$OUTPUT/libxt_${plugin}.so" "extensions/libxt_${plugin}.c" -Iinclude -I"$SDKTARGETSYSROOT/usr/include" -lxtables
    $STRIP --strip-unneeded "$OUTPUT/libxt_${plugin}.so"
done
mkdir -p "$OUTPUT/../bin"
$CC -Wall -Wextra -Werror "$PORT_ROOT/native-probe.c" -o "$OUTPUT/../bin/native-probe"
$STRIP --strip-unneeded "$OUTPUT/../bin/native-probe"
echo 'Native plugin build complete.'
