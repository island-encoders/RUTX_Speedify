#!/bin/sh
set -eu
# Public code/metadata must remain readable to RutOS's unprivileged web service.
# Account state helpers set their own private umask separately.
umask 022
cd "$(dirname "$0")"
[ "$(id -u)" = 0 ] || { echo 'Root required';exit 1; }
[ "$(cat /etc/version)" = RUTX_R_00.07.26.2 ] && [ "$(uname -r)" = 6.6.137 ] || { echo 'Requires RUTX 7.26.2 / kernel 6.6.137';exit 1; }
R=/usr/local/speedify-rutos
P=/usr/local/speedify-native
[ -x "$R/bin/run-speedify" ] || { echo 'Install core port 0.3.0 first';exit 1; }
(cd "$R" && sha256sum -c SHA256SUMS >/dev/null)
sha256sum -c SHA256SUMS
for file in controller.lua account.lua agent.lua api.lua services-wrapper.lua;do lua -e "assert(loadfile('$file'))";done
mkdir -p "$P"
if [ ! -f "$P/vendor-services.lua" ];then
 cp /usr/lib/lua/api/status/services.lua "$P/vendor-services.lua"
 sha256sum "$P/vendor-services.lua" > "$P/vendor-services.sha256"
fi
# Wrapper is deliberately pinned to this firmware and preserves its original collector.
lua -e 'local s=assert(loadfile("/usr/local/speedify-native/vendor-services.lua"))();local _,f=debug.getupvalue(s.GET_TYPE_status,1);assert(type(f)=="function")'
if [ -x /etc/init.d/speedify-control ] && /etc/init.d/speedify-control running;then /etc/init.d/speedify-control stop;fi
if [ -x /etc/init.d/speedify-agent ] && /etc/init.d/speedify-agent running;then /etc/init.d/speedify-agent stop;fi
cp controller.lua agent.lua run-daemon safe-start rawip-compat.so rawip-type services-wrapper.lua "$P/"
mkdir -p /usr/local/usr/lib/lua/api/services /usr/local/usr/lib/lua/api/status /usr/local/usr/share/vuci/path.d /usr/local/usr/share/vuci/menu.d /usr/local/usr/share/rpcd/acl.d /usr/local/usr/share/acl.d
cp account.lua /usr/local/usr/lib/lua/speedify_account.lua
cp api.lua /usr/local/usr/lib/lua/api/services/speedify.lua
cp services-wrapper.lua /usr/local/usr/lib/lua/api/status/speedify_services.lua
if grep -q speedify_services /usr/local/usr/share/vuci/path.d/services-status.json 2>/dev/null;then rm /usr/local/usr/share/vuci/path.d/services-status.json;fi
cp path.json /usr/local/usr/share/vuci/path.d/speedify.json
cp menu.json /usr/local/usr/share/vuci/menu.d/speedify.json
cp acl.json /usr/local/usr/share/rpcd/acl.d/speedify.json
cp ubus-acl.json /usr/local/usr/share/acl.d/api_speedify.json
kill -HUP "$(pidof ubusd)"
mkdir -p /usr/local/www/views/services
cp views/services/Speedify_* /usr/local/www/views/services/
cp agent.init /etc/init.d/speedify-agent
cp integration.init /etc/init.d/speedify-integration
cp speedify-control.init /etc/init.d/speedify-control
chmod 755 "$P/run-daemon" "$P/safe-start" /etc/init.d/speedify-agent /etc/init.d/speedify-control
chmod 755 /etc/init.d/speedify-integration
chmod -R go-w "$P"
/etc/init.d/speedify-agent enable
/etc/init.d/speedify-integration enable
/etc/init.d/speedify-integration start
/etc/init.d/speedify-control enable
/etc/init.d/speedify-rutos disable
/etc/init.d/speedify-agent start
/etc/init.d/speedify-control start
ubus call session reload_acls
ubus send vuci.notify '{"event":"reload_routes"}'
/etc/init.d/uhttpd restart
if [ -x /etc/init.d/speedify-web ];then
 if /etc/init.d/speedify-web running;then /etc/init.d/speedify-web stop;fi
 /etc/init.d/speedify-web disable
fi
echo 'Installed native Services > VPN > Speedify. Refresh the RutOS browser page.'
echo 'The former separate web server is stopped and disabled.'
