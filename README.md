# Speedify for Teltonika RUTX / RutOS

An experimental integration that brings Speedify account sign-in, bonding settings and connection monitoring into the native Teltonika RutOS web interface. It includes a private Speedify runtime builder, firmware-matched kernel dependency build scripts, and a compatibility fix that lets Speedify detect RutOS raw-IP LTE interfaces alongside Ethernet.

**Testers and contributors welcome!** Try it on compatible hardware, report what works or breaks, and help improve modem detection, packaging, security, recovery and bonding validation. Please read the compatibility limits before installing.

## What it does

- Adds **Services → VPN → Speedify** using the existing RutOS login, theme and web server.
- Adds a Speedify row and Settings link under **Status → Services**.
- Supports individual-account sign-in and Router License activation through Speedify's official browser portal, with sign-out/account switching.
- Provides bonding mode, transport and per-adapter priority controls, plus physical WAN traffic monitoring.
- Makes `qmimux` raw-IP cellular interfaces visible to Speedify without changing their real kernel interface type.
- Keeps the vendor glibc runtime private instead of replacing RutOS system libraries.

## Current status

Native integration **0.4.1**, core runtime port **0.3.0**, Speedify **17.3.0-12956**. Tested on **RUTX12, RUTX_R_00.07.26.2, Linux 6.6.137, ARMv7 Cortex-A7**.

Ethernet and one active LTE modem are detected. The second modem had no SIM during testing. The matcher handles all numeric `qmimux` names, but two live cellular links have **not** been validated. Sign-in URL generation and native API controls pass; paid account activation, live VPN bonding, throughput, failover, DNS/IPv6 leak prevention and a kill switch are **not validated**.

This is an independent community experiment, not an official Teltonika or Speedify product. Other models and firmware versions are untested. Do not force these kernel modules onto a different kernel.

## Licensing and account sign-in

Speedify remains proprietary and is **not included** in this repository. Obtain the client from [Speedify](https://support.speedify.com/article/922-manually-installing-on-openwrt) and use it under its terms. The builder checks the exact expected vendor package hash.

The individual-account option authenticates your own Speedify account; it does **not** change the router into a desktop client or bypass router-use licensing. See [Speedify account guidance](https://support.speedify.com/article/1089-create-speedify-account) and [Router License activation](https://support.speedify.com/article/927-how-to-sign-in-to-my-speedify-router).

## Automatic installation

On a matching router, connected through local Ethernet, download and review the installer, then run it as root:

```sh
curl -fL https://raw.githubusercontent.com/island-encoders/RUTX_Speedify/main/install.sh -o /tmp/install-speedify.sh
sh /tmp/install-speedify.sh
```

It downloads the official client directly from Speedify, downloads this project's matching kernel/native dependencies and UI, verifies pinned hashes, assembles the private runtime and installs both core and native integration. No Python, compiler, `ar` or `xz` is required on the router. Vendor package maintainer scripts are not run. Speedify itself is not mirrored here.

Use `--prepare-only` to download, assemble and validate without installing. Same-SDK candidates require `--allow-untested-model`; see [COMPATIBILITY.md](COMPATIBILITY.md). The default tested target is RUTX12 / RUTX_R_00.07.26.2 / kernel 6.6.137. Read [INSTALL.md](INSTALL.md) and keep an off-router backup first.

The installer starts the management daemon, with VPN auto-connect and default-route takeover off. **Connect** is a separate explicit action and can reload networking. An upstream package hash change is rejected rather than silently installing a different client.

## Repository layout

| Path | Contents |
| --- | --- |
| `core/` | Runtime builder, exact-kernel dependency scripts, compatibility module source and probes |
| `native/` | Vue page, REST extension, bounded ubus controller, LTE shim, installer and tests |
| `downloads/` | Native integration and firmware-matched support payloads; no proprietary Speedify client |
| `docs/VALIDATION.md` | Scope of actual checks and remaining gaps |

## Help test and improve it

Please open an [issue](https://github.com/island-encoders/RUTX_Speedify/issues) with your model, firmware, kernel, modem type, reproduction steps and a redacted result. Pull requests are welcome. Priority areas: dual-LTE validation, reconnect/reboot behavior, licensing/activation feedback, packaging for additional firmware versions, recovery and network safety.

Never include passwords, activation URLs/codes, account/session tokens, SIM identifiers, full router backups or unredacted diagnostic bundles. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Licenses

Original integration code is MIT-licensed; see [LICENSE](LICENSE). The Linux-derived UDP compatibility module is **GPL-2.0-only**, as identified in its source. Vendor examples, generated dependencies, Linux, iptables and other third-party materials retain their own licenses; see [THIRD_PARTY.md](THIRD_PARTY.md).
