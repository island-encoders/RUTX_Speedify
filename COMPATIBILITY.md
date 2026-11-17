# Teltonika model compatibility

Only the RUTX12 has been tested. The installer checks exact firmware, CPU, kernel, kernel-package version and the SHA256 of the stock TUN module against the tested baseline. It does not flash firmware or force module versions.

| Model | Status | Expected use |
| --- | --- | --- |
| RUTX12 | Tested on RutOS 7.26.2 / kernel 6.6.137 | Ethernet plus raw-IP LTE detection validated; second live modem and actual VPN bonding still unvalidated |
| RUTX09, RUTX11, RUTX14, RUTX50, RUTXR1 | Same-SDK candidates, untested | Potential cellular/Ethernet use, subject to actual modem interface type, matching baseline and testing |
| RUTX08, RUTX10 | Same-SDK candidates, untested | Wired/Wi-Fi WAN use as available; these models do not have an integrated cellular modem |
| RUT/RUTM/RUTC/TRB and other families | Unsupported by this release | Different architectures, kernel builds or native integrations require a separate port |

Teltonika groups the eight listed RUTX models under the same [RUTX SDK](https://wiki.teltonika-networks.com/view/Software_Development_Kit). That is evidence of a plausible shared build target, **not proof this integration works on every model**. See also [RUTX50 firmware](https://wiki.teltonika-networks.com/view/RUTX50_Firmware_Downloads) and [RUTX14 firmware](https://wiki.teltonika-networks.com/view/RUTX14_Firmware_Downloads).

Candidates require the explicit `--allow-untested-model` flag and still must pass every firmware/kernel/baseline check. Other firmware releases are refused even on a RUTX12. Do not downgrade newer hardware below its manufacturer-required minimum firmware just to satisfy this installer.

A second SIM slot is not necessarily a second simultaneous modem. RUTX12 has two radios; many dual-SIM models switch between SIMs on a single radio. Speedify can only bond independent live WAN connections. Detection of a model name or interface is not proof of usable bonded service.
