#!/bin/bash
# Build a private ARM32/glibc-loadable shim using RutOS SDK headers/compiler.
set -e
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
source "${1:?Usage: build-rawip.sh SDK_ROOT}/init-build-env"
# Deliberately no DT_NEEDED libc. dlsym resolves inside Speedify's glibc.
$CC -std=c11 -Os -Wall -Wextra -Werror -fPIC -shared -nostdlib -fno-stack-protector -Wl,-soname,rawip-compat.so -o "$HERE/rawip-compat.so" "$HERE/rawip-compat.c"
$READELF -d "$HERE/rawip-compat.so"
