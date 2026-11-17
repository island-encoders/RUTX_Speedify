# Installation and development

## Exact supported target

RUTX12 / RUTX_R_00.07.26.2 / kernel 6.6.137 / ARMv7 Cortex-A7. Other targets require rebuilding and validation, not a forced module install. Keep a configuration backup outside the router and work through local Ethernet.

## Automatic router installer

The top-level `install.sh` is the main entry point. It downloads the official Speedify IPK directly from the vendor, and verified support/native payloads from this repository. Run `sh install.sh --prepare-only` for a download-and-assembly check without installing. Normal invocation installs the core if absent, then installs or updates the native integration. Existing compatible core/account data is retained; the control daemon is restarted with automatic VPN routing off.

The firmware-matched support payload contains kernel modules and native plugins built from the documented SDK/netfilter sources, plus Debian's ARMHF libkeyutils with its copyright notice. Source/build references are in `core/`, `THIRD_PARTY.md` and `core/PROVENANCE.json`. A mismatch in any pinned download hash stops installation. No firmware update is attempted.

See COMPATIBILITY.md before using an untested same-SDK model. All other families and firmware are rejected.

## Manual core runtime build

Follow `core/README.txt`, `core/PROVENANCE.json` and the scripts in `core/` to obtain the exact SDK, netfilter source, official Speedify package and Debian keyutils package. Build the stock-kernel baseline, compare it with the matching router's stock TUN module, build dependencies, then run `verify_dependencies.py` and `build_port.py`.

The repository intentionally excludes the proprietary Speedify client, its glibc bundle, firmware images and SDK archives. The automatic installer retrieves the client directly from Speedify; the following instructions are for rebuilding the core/support payload yourself. Supply those inputs yourself from the official sources. The builder rejects input hash mismatches, including a newer vendor package served at the same URL; updating the pin requires a fresh compatibility audit.

Build the core archive and install it as described in `core/README.txt`. Check its runtime and platform requirements before adding the UI. Do not enable the old core init service alongside the native control service.

## Native package

Download the archive and `.sha256` file from `downloads/`, check the checksum, and copy the archive to the router. For routers without SFTP, legacy SCP may be required:

```sh
sha256sum -c speedify-native-0.4.0-rutx7262.tar.gz.sha256
scp -O speedify-native-0.4.0-rutx7262.tar.gz root@192.168.1.1:/tmp/
```

On the matching router, with the core runtime already installed:

```sh
mkdir -p /tmp/speedify-native-install
tar -xzf /tmp/speedify-native-0.4.0-rutx7262.tar.gz -C /tmp/speedify-native-install
cd /tmp/speedify-native-install/speedify-native
sha256sum -c SHA256SUMS
sh install.sh
```

Refresh RutOS, then open **Services → VPN → Speedify**. Choose Individual Speedify account or Router License account, generate a sign-in link, complete authentication on the official site and refresh status. Only one account can be active at a time. Router-use licensing still applies.

The management service starts with startup-connect and VPN default routing off. A fresh daemon restart does not automatically reconnect the VPN. The Connect action can prepare a named interface/firewall zone and reload networking. Production traffic, dual-LTE operation and leak prevention need independent validation.

## Rebuild and test the native package

With Node/npm and a Lua 5.1-compatible interpreter:

```sh
cd native
lua test-account.lua
node test-account-ui.mjs
bash build-ui.sh
```

Rebuild the ARM shim using the exact SDK:

```sh
bash build-rawip.sh /absolute/path/to/extracted/SDK
```

The shared object intentionally has no musl runtime dependency; Speedify's private glibc resolves `dlsym`. If you rebuild that binary after the UI, regenerate `SHA256SUMS` before installation. The included compiled native assets target the tested firmware.

## Removal

Run `sh uninstall.sh` from the native package. It stops Speedify, removes native registration and unmounts the status-table wrapper. It retains private runtime files, activation keys and any prepared network configuration. For explicit network rollback, consult the core `manage-port --unconfigure-network --ack-network-change` instructions.

The status-table wrapper uses a runtime bind mount and preserves the vendor module; it does not modify squashfs. Firmware updates require reassessment/rebuilding. The former separate dashboard server is disabled by the native installer.
