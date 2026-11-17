# Third-party notices

Speedify is proprietary and is not redistributed here. Obtain it from the vendor and comply with its terms and router-use entitlement. Official package locations and expected hashes are recorded in core/build_port.py and core/PROVENANCE.json.

core/kernel-compat/sfy_udp_lookup.c is derived from Linux 6.6.137 UDP code in the Teltonika SDK and is GPL-2.0-only. A GPLv2 copy is in core/GPL-2.0.txt. The firmware-matched support payload includes built Linux/netfilter modules and iptables plugins. Corresponding source locations, exact SDK/source archive hashes, custom GPL wrapper source and build scripts are in core/PROVENANCE.json and core/. The official SDK source is https://firmware.teltonika-networks.com/7.26.2/RUTX/RUTX_R_SDK_00.07.26.2.tar.gz; iptables source is https://www.netfilter.org/projects/iptables/files/iptables-1.8.10.tar.xz. Their upstream licenses apply.

The native UI follows Teltonika's SDK Vue/Vite example contract. ui-build/package-lock.json records pinned dependencies; those packages retain their individual licenses. Vue is externalized to the existing RutOS runtime. SDK build configuration/examples retain any applicable vendor notices. This repository's MIT license covers original integration code, not third-party code or trademarks.

The support payload includes Debian ARMHF keyutils 1.6.3-2 and its copyright/license notice in core/licenses/keyutils-copyright. Its source is available from https://deb.debian.org/debian/pool/main/k/keyutils/; the exact binary input hash is recorded in core/build_port.py. The private runtime builder preserves that notice. The Teltonika SDK, firmware, proprietary executables and glibc runtime bundle must be obtained separately.
