# Validation status

Latest native integration 0.4.0 was deployed and checked on a RUTX12 on 17 November 2026. Firmware: RUTX_R_00.07.26.2; kernel: 6.6.137; core port: 0.3.0.

Verified: native Services/VPN page and Services status row; authenticated REST status/settings; anonymous request rejection; bounded action validation; individual/router sign-in link generation with router role preserved; rejection of unknown account choices and unconfirmed sign-out; Ethernet and one active raw-IP LTE adapter detected; control socket loopback-only; separate dashboard server disabled. VPN default routing and startup-connect remain off after installation.

The core's isolated namespace tests passed BBR per-socket selection and real IPv4/IPv6 UDP TPROXY delivery. Stock and baseline TUN executable/read-only sections matched. Historical detailed core reports are in core/.

Account-flow mocks, UI payload tests and the vendor-locked Vue build passed. A direct interface-bound HTTPS check over the active LTE link passed. These results do not establish bonded VPN throughput.

Not validated: a second live LTE modem (no second SIM was fitted), paid account activation, live VPN bonding/throughput, failover, DNS/IPv6 leak prevention, kill switch, or other hardware/firmware. A matching name pattern alone is not evidence of a working second modem. No account sign-in was completed and no VPN Connect action was executed in these checks.

## Automatic installer verification

On 17 November 2026 the published installer ran successfully on the RUTX12 with --prepare-only. It fetched the official Speedify IPK and public support/native payloads over HTTPS, verified all pinned hashes, assembled the private runtime and passed loader checks. Every generated core file matched the already installed, previously tested runtime byte-for-byte. No installation or VPN state change was made by this check. A complete fresh installation was subsequently exercised successfully; see [FRESH_INSTALL_TEST.md](FRESH_INSTALL_TEST.md). The post-reboot service, dependency and API checks also passed.
