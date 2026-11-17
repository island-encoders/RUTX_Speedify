#!/bin/sh
# Download and assemble the official client on the router. No vendor scripts run.
set -eu
BASE=https://raw.githubusercontent.com/island-encoders/RUTX_Speedify/main
SPEEDIFY_URL=https://downloads.speedify.com/speedify_arm_cortex-a7_neon-vfpv4.ipk
SPEEDIFY_HASH=15b19220ecedec1c4d84731e0d0d2e19fd41bdd45e15eda5d0262d616859ea08
SUPPORT_HASH=165d91a60929e4fc4e1815c235723d33cddf8a3cbbbc7e0a5654b43ce751d3b7
NATIVE_HASH=f6f84a40ee41e1c18695912e2586b0982298c313f655e14948cecf26cc3e832b
TUN_HASH=6c206fdaa7e28e7c9bbceb2831c9f0443b0e9ce2f1393699a1a3047e7cb5afc7
PREPARE=0
ALLOW_UNTESTED=0
while [ "$#" -gt 0 ];do
 case "$1" in
  --prepare-only) PREPARE=1;;
  --allow-untested-model) ALLOW_UNTESTED=1;;
  --help) echo 'Usage: sh install.sh [--prepare-only] [--allow-untested-model]';exit 0;;
  *) echo "Unknown option: $1" >&2;exit 1;;
 esac
 shift
done
die() { echo "ERROR: $*" >&2;exit 1; }
[ "$(id -u)" = 0 ] || die 'Run as root on the router, through local Ethernet.'
[ "$(cat /etc/version)" = RUTX_R_00.07.26.2 ] || die 'Unsupported firmware; requires RUTX_R_00.07.26.2. No firmware upgrade is performed.'
[ "$(uname -r)" = 6.6.137 ] && [ "$(uname -m)" = armv7l ] || die 'Unsupported kernel or CPU; do not force these modules.'
MODEL=$(cat /tmp/sysinfo/model)
case "$MODEL" in
 RUTX12) :;;
 RUTX08|RUTX09|RUTX10|RUTX11|RUTX14|RUTX50|RUTXR1)
  [ "$ALLOW_UNTESTED" = 1 ] || die "$MODEL is a same-SDK candidate, not validated. Read COMPATIBILITY.md; use --allow-untested-model only for deliberate testing.";;
 *) die "Unsupported model: $MODEL";;
esac
for cmd in lua tar sha256sum find sort cp mkdir mktemp;do command -v "$cmd" >/dev/null || die "Missing tool: $cmd";done
echo "$TUN_HASH  /lib/modules/6.6.137/tun.ko" | sha256sum -c - >/dev/null || die 'Stock kernel baseline differs from tested build.'
[ "$(opkg status kernel-6.6.137 | awk '/^Version:/ {print $2}')" = 6.6-r0 ] || die 'Unexpected kernel package.'
FREE=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
[ "${FREE:-0}" -ge 49152 ] || die 'At least 48 MiB available RAM is required for staging.'
WORK=$(mktemp -d /tmp/speedify-setup.XXXXXX)
KEEP=0
cleanup() { if [ "$KEEP" = 0 ];then case "$WORK" in /tmp/speedify-setup.*) rm -rf "$WORK";; esac;fi; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
fetch() {
 url=$1;dest=$2;hash=$3
 echo "Downloading $(basename "$dest")"
 if command -v curl >/dev/null;then curl --fail --location --proto '=https' --proto-redir '=https' --connect-timeout 20 --max-time 300 --retry 2 --output "$dest" "$url"
 elif command -v wget >/dev/null;then wget -O "$dest" "$url"
 else die 'Install curl or wget with HTTPS support first.';fi
 echo "$hash  $dest" | sha256sum -c - || die 'Download hash mismatch. Upstream may have changed; update requires a compatibility review.'
}
echo "Target: $MODEL / RUTX_R_00.07.26.2 / kernel 6.6.137"
fetch "$SPEEDIFY_URL" "$WORK/speedify.ipk" "$SPEEDIFY_HASH"
fetch "$BASE/downloads/rutx-7.26.2-core-support.tar.gz" "$WORK/support.tar.gz" "$SUPPORT_HASH"
fetch "$BASE/downloads/speedify-native-0.4.0-rutx7262.tar.gz" "$WORK/native.tar.gz" "$NATIVE_HASH"
mkdir "$WORK/support" "$WORK/vendor-outer" "$WORK/vendor" "$WORK/native"
tar -xzf "$WORK/support.tar.gz" -C "$WORK/support"
(cd "$WORK/support" && sha256sum -c SHA256SUMS >/dev/null) || die 'Support payload verification failed.'
tar -xzf "$WORK/speedify.ipk" -C "$WORK/vendor-outer" ./data.tar.gz
tar -xzf "$WORK/vendor-outer/data.tar.gz" -C "$WORK/vendor" -T "$WORK/support/vendor-files.txt"
CORE=$WORK/support/core
while IFS= read -r name;do
 rel=${name#./};rel=${rel#usr/share/speedify/}
 case "$rel" in speedify|speedify_cli|cacert.pem|lib/arm-linux-gnueabihf/*) :;;*) die 'Unexpected vendor file path';; esac
 [ -f "$WORK/vendor/$name" ] && [ ! -L "$WORK/vendor/$name" ] || die 'Vendor payload must contain regular files.'
 mkdir -p "$CORE/runtime/$(dirname "$rel")"
 cp "$WORK/vendor/$name" "$CORE/runtime/$rel"
done < "$WORK/support/vendor-files.txt"
chmod 755 "$CORE/runtime/speedify" "$CORE/runtime/speedify_cli" "$CORE/runtime/lib/arm-linux-gnueabihf/ld-linux-armhf.so.3"
(cd "$CORE" && find . -type f ! -name SHA256SUMS | sed 's|^./||' | sort | while IFS= read -r file;do sha256sum "$file";done >SHA256SUMS)
(cd "$CORE" && sha256sum -c SHA256SUMS >/dev/null)
"$CORE/bin/check-runtime"
tar -xzf "$WORK/native.tar.gz" -C "$WORK/native"
(cd "$WORK/native/speedify-native" && sha256sum -c SHA256SUMS >/dev/null)
if [ "$PREPARE" = 1 ];then
 KEEP=1
 echo "Downloads, checksums and private runtime validated. Nothing installed. Staging: $WORK"
 exit 0
fi
if [ -d /usr/local/speedify-rutos ];then
 /usr/local/speedify-rutos/bin/manage-port --load-dependencies
 /usr/local/speedify-rutos/bin/manage-port --check || die 'Existing core installation is incompatible; resolve it before continuing.'
 echo 'Compatible core already installed; retaining it and its account state.'
else
 "$CORE/bin/manage-port" --install-files
 /usr/local/speedify-rutos/bin/manage-port --load-dependencies
 /usr/local/speedify-rutos/bin/manage-port --check
fi
sh "$WORK/native/speedify-native/install.sh"
echo 'Complete: Services > VPN > Speedify. Sign in and check router-use entitlement.'
echo 'Management service enabled; automatic VPN connection remains off.'
