#!/bin/sh
set -eu
[ "$(id -u)" = 0 ] || exit 1
if /etc/init.d/speedify-control running;then
 /usr/local/speedify-rutos/bin/run-speedify cli disconnect >/dev/null 2>&1 || true
 /usr/local/speedify-rutos/bin/run-speedify cli route default off >/dev/null 2>&1 || true
 /etc/init.d/speedify-control stop || true
fi
/etc/init.d/speedify-control disable
/etc/init.d/speedify-agent stop || true
/etc/init.d/speedify-agent disable
/etc/init.d/speedify-integration stop
/etc/init.d/speedify-integration disable
rm -f /usr/local/usr/lib/lua/speedify_account.lua
rm -f /usr/local/usr/lib/lua/api/services/speedify.lua /usr/local/usr/lib/lua/api/status/speedify_services.lua /usr/local/usr/share/vuci/path.d/speedify.json /usr/local/usr/share/vuci/menu.d/speedify.json /usr/local/usr/share/rpcd/acl.d/speedify.json /usr/local/usr/share/acl.d/api_speedify.json
kill -HUP "$(pidof ubusd)"
ubus call session reload_acls
ubus send vuci.notify '{"event":"reload_routes"}'
/etc/init.d/uhttpd restart
echo 'Native integration removed and Speedify stopped. Private files, activation keys and network configuration retained.'
