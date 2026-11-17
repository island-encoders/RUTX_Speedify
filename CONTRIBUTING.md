# Testing and contributing

Thanks for helping test and improve this experimental integration. Issues and pull requests are welcome.

For a useful report, include the router model, exact RutOS and kernel versions, modem/interface types, the action you took, expected behavior and a small redacted result. Start with detection and management-plane checks before directing important traffic through an unvalidated VPN configuration.

Useful contributions include a second live LTE modem test, reconnect/reboot behavior, performance/resource measurements, native RutOS UX improvements, rollback, security review and reproducible builds for newer firmware. Clearly separate actual on-device evidence from simulated tests and intended support.

Run the applicable Lua, Node and build checks in INSTALL.md. Changes to kernel dependencies require a matching stock baseline and on-device validation. Preserve provenance, licensing notices, firmware checks and the distinction between account sign-in and router entitlement.

Do not post passwords, tokens, activation codes/URLs, SIM identifiers, public IP/location details or router backups. Share only minimal redacted diagnostics. Never commit vendor client/firmware archives or private test-device state.
