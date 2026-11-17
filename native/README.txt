Speedify native RutOS integration - experimental 0.4.0
Published source and native package. See ../README.md, ../INSTALL.md and ../docs/VALIDATION.md for current status and contribution guidance.

Page: https://192.168.1.1/services/vpn/speedify
Menu: Services > VPN > Speedify
Status: Status > Services > Speedify > Settings
Uses the existing RutOS HTTPS server, login session, role permissions, form
components, table components and light/dark theme. No separate web server.

Includes raw-IP LTE detection compatibility for all qmimux numeric interfaces.
Live validated adapters: Ethernet eth1 and Telstra LTE1 qmimux0.
Modem 2 reports SIM not inserted; the owner confirmed no SIM is fitted.
Insert an active data SIM and let RutOS establish its data connection before
expecting a third Speedify adapter. No fabricated offline adapter is added.
Speedify's underlying type says Ethernet for corrected raw-IP devices, but ISP
metadata identifies Cellular and the page labels the modem links LTE 1 / LTE 2.

Requires the tested Speedify RutOS core port 0.3.0, RUTX firmware 7.26.2 and
kernel 6.6.137. Extract the archive, then run sh install.sh as root.
The source, compiled Vue assets and ARM compatibility library are included.
The installer verifies its manifest and the unchanged core manifest.
Upgrades restart the control daemon with startup-connect and VPN default routing
off. Existing activation keys and settings under /etc/speedify-rutos are retained.

Enable controls the running management daemon. Start service on boot controls
its boot entry; neither automatically connects the VPN after a restart.
Save & Apply saves the service, boot, mode and transport preferences.
Connection priorities save immediately, like other direct service actions.
Generate activation code links this device to an account on my.speedify.com.
A valid Speedify Router License is required for VPN use.
Connect requires the Prepare network for VPN acknowledgement. It can create a
named interface/firewall zone, reload networking and enable the VPN default route.
No live Connect, paid activation or bonded VPN throughput test was performed.
Physical WAN rates include traffic outside Speedify and are not VPN throughput.

Implementation
- UI: vendor-SDK Vue 3 / Vite native plugin under /usr/local/www/views/services.
- REST: /api/speedify/status and /api/speedify/actions/execute, registered through
  the normal /usr/local/usr/share/vuci/path.d and rpcd ACL extension directories.
- Privileged operations: a local Lua ubus agent, not a web server. It accepts
  fixed actions and validated values; it never accepts a shell command or path.
  Fork/exec uses argument arrays. The native HTTP layer runs unprivileged.
- Raw-IP fix: daemon-only glibc --preload redirects read-only sysfs type reads
  for /sys/class/net/qmimux[0-9]+/type. The real kernel type stays 65534.
  No ioctl, netlink, routing or packet-framing override. No global LD_PRELOAD.
- Status > Services is hard-coded by this firmware. A firmware-pinned bind mount
  wraps its module at runtime and preserves the exact original vendor collector,
  appending Speedify. No squashfs contents are changed. The bind is restored by
  /etc/init.d/speedify-integration before the native web service starts.
  The original bytecode module is retained as vendor-services.lua in the private
  prefix. This compatibility wrapper must be reassessed after firmware upgrades.

Services
/etc/init.d/speedify-integration — native status-list integration, boot enabled
/etc/init.d/speedify-agent — local ubus controller, boot enabled
/etc/init.d/speedify-control — Speedify daemon with LTE compatibility, boot enabled
/etc/init.d/speedify-web — former separate dashboard, stopped and boot disabled
/etc/init.d/speedify-rutos — original core init, disabled to avoid duplicate daemons

Recovery
sh uninstall.sh removes native registration, restores the original services
module by unmounting the wrapper, and stops/disables the agent and integration.
It also stops/disables the control daemon. It leaves activation keys, the private runtime and any prepared VPN network
configuration intact. Core manage-port --unconfigure-network provides explicit
network rollback if needed. Firmware upgrades may remove custom packages.

Build
Run bash build-ui.sh with Node/npm available. UI uses the matching official SDK example's package-lock.json and vite.config.js
with Vue externalized to the native page runtime. Source: Speedify.vue.
Raw-IP library: bash build-rawip.sh /path/to/matching/extracted/SDK
Path regression tests: cc -fsanitize=address,undefined test-rawip.c -ldl -o test-rawip
The private shared object has no musl libc dependency; glibc supplies dlsym.

References
https://wiki.teltonika-networks.com/view/RUTOS_Software_Development_Kit_(SDK)_Instruction
https://support.speedify.com/article/285-speedify-cli
https://support.speedify.com/article/923-how-to-buy-a-router-license
https://support.speedify.com/article/930-bonding-connections-openwrt
