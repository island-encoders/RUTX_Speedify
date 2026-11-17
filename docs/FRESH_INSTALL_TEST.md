# Fresh-install test — RUTX12

Performed 17 November 2026 using the published top-level GitHub installer from commit `e70328b8cdb901c9c77a9e45c05b6e0400d7e187`.

## Procedure

1. Verified firmware `RUTX_R_00.07.26.2`, kernel `6.6.137`, signed-out state and no prepared VPN forwarding.
2. Created a private rollback backup and verified its off-router copy. Backups/account data are not published.
3. Uninstalled native registration and moved the old core runtime, native prefix, account state, init files and page assets out of their installed locations.
4. Downloaded `install.sh` directly from the public repository and ran it normally, without `--prepare-only`.

## Results before reboot

- Installer exit status: **0**. The new-install core path was exercised, not the existing-core update path.
- Official Speedify package, support payload and native package downloaded and passed pinned hash verification.
- Core installed from scratch, matching dependencies loaded, platform check reported zero blockers and native integration installed.
- Network and firewall configuration files were byte-for-byte unchanged.
- Control daemon, ubus agent and native status integration had enabled boot entries.
- Native API: individual/router sign-in URL generation passed; invalid account and unconfirmed sign-out rejected; unauthenticated status rejected.
- Ethernet and one active LTE modem detected. Second live modem remains untested because no SIM was fitted.
- Speedify remained signed out; default VPN route and startup-connect stayed off. Control socket was loopback-only and port 8443 was absent.

## Corrections published as native 0.4.1

The successful install emitted a misleading `service delete speedify-web: Not found` message when the legacy dashboard init file existed but its service was already stopped. The installer now checks whether a service is running before stopping it. Both installer entry points also set an explicit public-code umask; private account helpers retain their separate restrictive umask.

The native package was regenerated and its pinned hash updated in the top-level installer. Shell syntax checks passed. On-device revalidation of these final corrections is pending.

## Reboot check passed

After reboot, the USB Ethernet connection temporarily reported no carrier, then recovered without an adapter reset. The native control daemon and ubus agent started automatically, the status-module bind mount was present, and the platform check again reported zero blockers. Native API/account-link checks passed again, with Ethernet and LTE detected and VPN routing/auto-connect off.

Paid activation, live VPN bonding, throughput and failover remain untested. No license code was redeemed and no VPN Connect action was performed.
