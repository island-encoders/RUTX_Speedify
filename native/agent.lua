#!/usr/bin/lua
local ubus=require('ubus')
local loop=require('uloop')
local json=require('luci.jsonc')
local controller=dofile('/usr/local/speedify-native/controller.lua')
loop.init()
local conn=assert(ubus.connect())
local cached,at
local function status(req)
 local now=os.time()
 if not cached or not at or now-at>=2 then cached=controller.status();at=now end
 conn:reply(req,{ok=true,data=cached})
end
local function command(req,msg)
 local body=msg.payload
 if type(body)~='string' or #body>4096 then conn:reply(req,{ok=false,error='Invalid request size'});return end
 cached=nil;at=nil
 local ok,result=pcall(controller.command,json.parse(body))
 conn:reply(req,ok and result or {ok=false,error='Speedify controller failed; inspect router logs'})
end
conn:add({speedify={status={status,{}},command={command,{payload=ubus.STRING}}}})
loop.run()
