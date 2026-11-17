#!/bin/bash
# Requires a completed stock-config baseline build in the exact 7.26.2 SDK.
set -e
SDK=${1:?Usage: build-kmods.sh SDK_ROOT OUTPUT_DIR}
OUTPUT=${2:?}
PORT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$SDK/init-build-env"
export LC_ALL=C ARCH=arm CROSS_COMPILE=arm-poky-linux-musleabi-
cd "$SDK/assets/kernel-src"
[ -f .baseline-complete ] && [ -f .config.stock-baseline ] && [ -f Module.symvers.stock-baseline ] || {
    echo 'Build and compare the unmodified SDK baseline first.' >&2; exit 1;
}
[ "$(make -s kernelrelease)" = 6.6.137 ] || { echo 'Wrong kernel source'; exit 1; }
cp .config.stock-baseline .config
for name in TCP_CONG_BBR NF_TPROXY_IPV4 NF_TPROXY_IPV6 NF_SOCKET_IPV4 NF_SOCKET_IPV6 NETFILTER_XT_TARGET_TPROXY NETFILTER_XT_MATCH_SOCKET NETFILTER_XT_MATCH_ADDRTYPE NETFILTER_XT_MATCH_OWNER NETFILTER_XT_MATCH_PKTTYPE NETFILTER_XT_MATCH_QUOTA; do
    scripts/config --module "$name"
done
make olddefconfig
python3 - <<'PY'
from pathlib import Path
def cfg(path):
    return dict(line.split('=',1) for line in Path(path).read_text().splitlines() if line.startswith('CONFIG_') and '=' in line)
a,b=cfg('.config.stock-baseline'),cfg('.config')
changes={k:(a.get(k,'n'),b.get(k,'n')) for k in a.keys()|b.keys() if a.get(k,'n')!=b.get(k,'n')}
print('Kernel configuration changes:',changes)
if any(old!='n' or new!='m' for old,new in changes.values()):
    raise SystemExit('Refusing build: changes are not exclusively disabled-to-module additions')
PY
cp "$PORT_ROOT/kernel-compat/sfy_udp_lookup.c" net/netfilter/sfy_udp_lookup.c
# Build the shim and its consumers in one Kbuild pass, so modpost can resolve
# the real exported wrappers and record the module dependency automatically.
grep -qxF 'obj-m += sfy_udp_lookup.o' net/netfilter/Makefile || printf '\nobj-m += sfy_udp_lookup.o\n' >>net/netfilter/Makefile
make -j6 modules
mkdir -p "$OUTPUT"
for name in tcp_bbr nf_tproxy_ipv4 nf_tproxy_ipv6 nf_socket_ipv4 nf_socket_ipv6 xt_TPROXY xt_socket xt_addrtype xt_owner xt_pkttype xt_quota; do
    file=$(find net -name "$name.ko" -print -quit)
    [ -n "$file" ] || { echo "Missing built module: $name"; exit 1; }
    cp "$file" "$OUTPUT/$name.ko"
    "${CROSS_COMPILE}strip" --strip-debug "$OUTPUT/$name.ko"
done
cp net/netfilter/sfy_udp_lookup.ko "$OUTPUT/sfy_udp_lookup.ko"
"${CROSS_COMPILE}strip" --strip-debug "$OUTPUT/sfy_udp_lookup.ko"
cp .config "$OUTPUT/kernel.config"
echo 'Speedify kernel dependencies built.'
