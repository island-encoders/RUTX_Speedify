local j=require('luci.jsonc')
local n=require('nixio')
local M={}
local Account=require('speedify_account')
local R='/usr/local/speedify-rutos'
local function read(p) local f=io.open(p);if not f then return '' end;local s=f:read('*a');f:close();return s end
local function run(args)
 local r,w=n.pipe();local pid=n.fork()
 if pid==0 then r:close();n.dup(w,n.stdout);n.dup(w,n.stderr);w:close();n.exec('/usr/bin/timeout',args[1]==R..'/bin/run-speedify' and '15' or '80',unpack(args));os.exit(127) end
 w:close();local out=''
 while true do local s=r:read(4096);if not s or #s==0 then break end;out=out..s;if #out>262144 then n.kill(pid,9);break end end
 r:close();local _,_,code=n.waitpid(pid);return j.parse(out),out,code
end
local function cli(...) return run({R..'/bin/run-speedify','cli',...}) end
function M.status()
 local state,_,code=cli('state')
 local s={online=code==0,state=state,time=os.time(),links={},modems={}}
 if s.online then s.settings=cli('show','settings');s.adapters=cli('show','adapters');s.user=cli('show','user');s.server=cli('show','currentserver') end
 for i=0,1 do local pin=run({'/bin/ubus','call','gsm.modem'..i,'get_pin_state'});s.modems[#s.modems+1]={name='mob'..(i+1)..'s1a1',label='LTE '..(i+1),sim=pin and pin.state or 'Unknown'} end
 local net=run({'/bin/ubus','call','network.interface','dump'})
 local children,seen={},{}
 for _,v in ipairs((net or {}).interface or {}) do if (v.interface or ''):match('_4$') then children[v.interface:gsub('_4$','')]=true end end
 for _,v in ipairs((net or {}).interface or {}) do
  local name=v.interface or ''
  if name=='wan' or (name:match('^mob') and not name:match('_6$') and not children[name]) then
   local dev=v.l3_device or v.device or '';local valid=dev:match('^[%w_.%-]+$')
   if dev=='' or not seen[dev] then s.links[#s.links+1]={name=name:gsub('_4$',''),device=dev,up=v.up or false,rx=valid and tonumber(read('/sys/class/net/'..dev..'/statistics/rx_bytes')) or 0,tx=valid and tonumber(read('/sys/class/net/'..dev..'/statistics/tx_bytes')) or 0};seen[dev]=true end
  end
 end
 local _,_,enabled=run({'/etc/init.d/speedify-control','enabled'});s.bootEnabled=enabled==0
 return s
end
local function contains(list,v) return type(v)=='string' and ('|'..list..'|'):find('|'..v..'|',1,true) end
local function failure(message) return {ok=false,error=message} end
function M.command(a)
 if type(a)~='table' then return failure('Invalid request') end
 if a.action=='signin' then return Account.signin(cli,a.account) end
 if a.action=='signout' then return Account.signout(cli,a.acknowledge) end
 local value,out,code
 if a.action=='mode' and contains('speed|streaming|redundant',a.value) then value,out,code=cli('mode',a.value)
 elseif a.action=='transport' and contains('auto|tcp|tcp-multi|udp|https',a.value) then value,out,code=cli('transport',a.value)
 elseif a.action=='preferences' and contains('speed|streaming|redundant',a.mode) and contains('auto|tcp|tcp-multi|udp|https',a.transport) then
  local old=cli('show','settings');if not old then return failure('Start the Speedify service first') end
  value,out,code=cli('mode',a.mode);if code~=0 then return failure(out) end
  value,out,code=cli('transport',a.transport);if code~=0 then cli('mode',old.bondingMode);return failure(out) end
 elseif a.action=='priority' and type(a.id)=='string' and #a.id<=160 and contains('automatic|always|secondary|backup|never',a.value) then
  local found=false;local adapters=cli('show','adapters')
  for _,v in pairs(adapters or {}) do if type(v)=='table' and v.adapterID==a.id then found=true end end
  if not found then return failure('Unknown Speedify adapter') end
  value,out,code=cli('adapter','priority',a.id,a.value)
 elseif a.action=='activation' then value,out,code=cli('activationcode')
 elseif a.action=='disconnect' then cli('disconnect');cli('startupconnect','off');value,out,code=cli('route','default','off')
 elseif a.action=='connect' and a.acknowledge==true then
  local state=cli('state');if not state or state.state=='LOGGED_OUT' then return failure('Activate this router with a Speedify Router License before connecting') end
  local _,raw=run({'/sbin/uci','-q','get','speedify_rutos.core.network_ready'})
  if not raw:match('^1%s*$') then local _,_,ready=run({R..'/bin/manage-port','--configure-network','--ack-network-change'});if ready~=0 then return failure('Network preparation failed; inspect router logs') end end
  cli('route','default','on');value,out,code=cli('connect');if code~=0 then cli('route','default','off') end
 elseif a.action=='start' or a.action=='stop' then value,out,code=run({'/etc/init.d/speedify-control',a.action})
 elseif a.action=='boot' and type(a.enabled)=='boolean' then value,out,code=run({'/etc/init.d/speedify-control',a.enabled and 'enable' or 'disable'})
 else return failure('Unknown action or invalid value') end
 if code~=0 then return failure(out~='' and out or 'Command failed') end
 return {ok=true,data=value or {}}
end
return M
