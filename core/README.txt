CORE RUNTIME DOCUMENTATION / HISTORICAL CORE VALIDATION
For the combined native integration and current status, see ../README.md and ../INSTALL.md. The core init service remains disabled when the native control service is used.

Speedify RutOS installer 0.3.0 — RUTX / official RutOS 7.26.2
Validated on the user's RUTX12, 16 November 2026

RESULT AND CURRENT ROUTER STATE
The private runtime and installer are implemented and installed on the RUTX12.
Speedify 17.3.0's daemon and CLI work in an isolated router network namespace.
The new native dependencies passed BBR and real IPv4/IPv6 UDP TPROXY packet tests.
The installed platform checker reports zero blockers.

Speedify is NOT active on the live network. Its service is disabled at boot,
enabled=0 and network_ready=0. No Router License was available, so activation,
live WAN bonding, throughput, failover and live-network integration remain
untested. No DNS/IPv6 leak-prevention or kill-switch guarantee is claimed.
The host routing policy and firewall rules were unchanged by the isolated tests.
The system default TCP congestion-control algorithm remains cubic.

COMPATIBILITY
Exact target: official RUTX_R_00.07.26.2, kernel 6.6.137, ARMv7 Cortex-A7.
RutOS package architecture: cortexa7hf-neon-vfpv4.
Kernel package: kernel-6.6.137, version 6.6-r0.
Module vermagic: 6.6.137 SMP mod_unload ARMv7 p2v8.
The installer rejects other firmware/kernel releases. Only this RUTX12 has
been tested; do not assume support for arbitrary Teltonika models or firmware.
This replaces the earlier 7.18.3 development prototype.

INSTALL ON A MATCHING ROUTER
The current user's router is already installed; repeating installation is
deliberately refused. For another matching device, connect by local Ethernet.
Keep an off-router configuration backup. Check the archive SHA256 against the
provided .sha256 file before extracting or copying it.

On the PC, copy the release archive (legacy SCP if the router lacks SFTP):
  scp -O speedify-rutos-0.3.0-rutx7262.tar.gz root@192.168.1.1:/tmp/
  ssh root@192.168.1.1

On the router:
  mkdir -p /tmp/speedify-install
  tar -xzf /tmp/speedify-rutos-0.3.0-rutx7262.tar.gz -C /tmp/speedify-install
  cd /tmp/speedify-install/speedify-rutos
  sha256sum -c SHA256SUMS
  sh bin/manage-port --install-files
  /usr/local/speedify-rutos/bin/manage-port --load-dependencies
  /usr/local/speedify-rutos/bin/manage-port --check

--install-files checks identity, input hashes, free space and ELF loading. It
copies only manifest-listed regular files into its dedicated prefix, verifies
the installed payload and adds a disabled procd service and UCI configuration.
An incomplete file installation is removed automatically. It does not start
the live daemon, configure LAN forwarding or change WAN settings.
--load-dependencies registers the matching kernel modules and prepares a private
iptables plugin directory. It changes no network rules or global TCP default.
After a reboot, modules are loaded again when an enabled service starts; while
the service is disabled, use --load-dependencies before checking or smoke testing.

ISOLATED FUNCTIONAL TEST
  /usr/local/speedify-rutos/bin/smoke-test

This creates a temporary network namespace with loopback only. It tests BBR
per-socket selection and IPv4/IPv6 UDP packets delivered through TPROXY, then
starts the real Speedify daemon and queries its settings through the CLI.
The test uses separate namespace routing tables and no WAN interface. It stops its daemon
and removes the namespace afterward. Evidence is retained in the printed
/tmp/sfy-smoke.* directory, which may be deleted after review.
Both the staging copy and persistent installed copy passed this test.

WHAT IS INSTALLED
  /usr/local/speedify-rutos/       private executables, libraries and dependencies
  /etc/init.d/speedify-rutos       procd lifecycle script, disabled initially
  /etc/config/speedify_rutos       enabled/network_ready flags, both initially 0

The official Speedify executable and glibc libraries run through an explicit
private loader. No /lib glibc links or replacement system libraries are added.
The private libkeyutils comes from Debian ARMHF, as Speedify dlopens that library.
Native iptables plugins are built for RutOS's musl libc and iptables 1.8.10.
XTABLES_LIBDIR selects the private directory for Speedify's native child commands;
no glibc LD_LIBRARY_PATH is exported to the native router tools.
The deployment uses a private directory, not forced/incompatible opkg packages.
This is a CLI-only port; it adds no web UI and leaves RutOS web administration intact.

KERNEL DEPENDENCIES
Twelve modules are bundled: BBR, TPROXY/socket helpers for IPv4 and IPv6,
xt_TPROXY, xt_socket, xt_addrtype, xt_owner, xt_pkttype, xt_quota, and the small
sfy_udp_lookup compatibility module.

The stock kernel omits udp4_lib_lookup/udp6_lib_lookup when netfilter proxy
features are disabled. The compatibility module supplies the matching upstream
wrappers using the already exported __udp4_lib_lookup/__udp6_lib_lookup APIs.
It uses the same per-network UDP table and socket reference-count behavior as
the 6.6.137 kernel source. Source is included under kernel-compat/.
No kernel code patching, symbol-address lookup, forced version acceptance or
ignored linker errors is used. Kbuild resolves the real module dependencies.

BUILD FROM SOURCE
Use Linux or WSL with native Linux storage for the SDK build (not a Windows
filesystem directory). The official SDK contains the cross toolchain and
Puffin documentation. This work used an existing Ubuntu WSL distribution and
/var/tmp/rutx-speedify-sdk-7.26.2 because that instance clears /tmp on shutdown.

Official sources and hashes are recorded in PROVENANCE.json. Inputs:
  RUTX_R_SDK_00.07.26.2.tar.gz from Teltonika
  iptables-1.8.10.tar.xz from netfilter.org
  speedify_arm_cortex-a7_neon-vfpv4.ipk from Speedify
  libkeyutils1_1.6.3-2_armhf.deb from Debian
  stock tun.ko copied read-only from the exact firmware's /lib/modules/6.6.137/

Use absolute paths in these build commands:
  bash build-baseline.sh /abs/sdk /abs/stock-tun.ko /abs/comparison.json
  bash build-kmods.sh /abs/sdk /abs/dependencies/kmods
  bash build-native-plugins.sh /abs/sdk /abs/iptables-1.8.10.tar.xz /abs/dependencies/plugins
  python verify_dependencies.py /abs/dependencies --baseline /abs/comparison.json
  python build_port.py --speedify /abs/speedify.ipk --keyutils /abs/keyutils.deb --dependencies /abs/dependencies --output /abs/fresh-output-directory

The baseline build reproduces the stock configuration. Executable and read-only
sections of its TUN module matched the router's stock copy byte-for-byte.
The dependency build allows only disabled-to-module config additions and builds
the compatibility shim and consumers together, with strict symbol resolution.
The verifier checks ARM ELF format, module identity/vermagic, compiler version,
baseline comparison and native plugin format before generating file hashes.
The runtime builder verifies pinned vendor inputs and each dependency hash.
GCC reports musleabi/gnueabi aliases within this SDK; the actual baseline section
comparison passed, and all modules and packets were subsequently tested on-device.
Do not reuse these modules after a firmware update; build and validate again.

Validation tests against real built ELF artifacts:
  python tests/test_dependencies.py /abs/dependencies -v

LATER: LICENSE ACTIVATION AND LIVE NETWORK SETUP
These steps were NOT run on the live network. Acquire a Speedify Router License
first. Review WAN metrics/policy, DNS and IPv6 handling, and any other VPNs before
enabling from local Ethernet. The second cellular interface was already down;
it must be made usable before dual-cellular bonding can be validated.

  /usr/local/speedify-rutos/bin/manage-port --configure-network --ack-network-change
  /usr/local/speedify-rutos/bin/manage-port --enable --ack-start-daemon
  /usr/local/speedify-rutos/bin/run-speedify cli activationcode

Open the returned Speedify URL and sign in in your own browser. Then:
  /usr/local/speedify-rutos/bin/run-speedify cli show user

Network setup saves the original network/firewall files under
/etc/speedify-rutos and creates only named sfyrut sections and LAN-to-tunnel
forwarding. It reloads network/firewall services and can interrupt connectivity.
It does not rewrite multi-WAN policy, DNS, IPv6 or another VPN configuration.
Validate each uplink independently, both together, modem loss/recovery, reboot,
DNS/IPv6 behavior and resource use before relying on the deployment.

DISABLE / REMOVE
  /usr/local/speedify-rutos/bin/manage-port --disable
If its live network configuration was previously applied:
  /usr/local/speedify-rutos/bin/manage-port --unconfigure-network --ack-network-change
Then remove its private files:
  /usr/local/speedify-rutos/bin/manage-port --remove-files

Account data/backups under /etc/speedify-rutos are retained for deliberate review.
Loaded kernel modules may remain registered until reboot; removal does not unload
modules that might be in use by another application.

EVIDENCE AND LICENSING
ROUTER-VALIDATION.txt contains the actual installed-device test results and
checksums. BASELINE-COMPARISON.json records the stock/built section comparison.
BUILD-VALIDATION.txt records five positive/negative artifact tests and syntax
checks. DEPENDENCIES.json and PROVENANCE.json identify the native build inputs.
Speedify remains proprietary software used under its own terms and Router License.
The GPL compatibility module source and its license identifier are included.
The native probe is MIT-licensed; the bundled Debian keyutils copyright notice
is preserved. Upstream kernel, iptables and library licensing remains applicable.

REFERENCES
https://firmware.teltonika-networks.com/7.26.2/RUTX/RUTX_R_SDK_00.07.26.2.tar.gz
https://wiki.teltonika-networks.com/view/Software_Development_Kit
https://www.netfilter.org/projects/iptables/files/iptables-1.8.10.tar.xz
https://support.speedify.com/article/922-manually-installing-on-openwrt
https://support.speedify.com/article/927-how-to-sign-in-to-my-speedify-router
https://packages.debian.org/bookworm/armhf/libkeyutils1/download
