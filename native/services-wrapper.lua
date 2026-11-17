-- Preserve the exact vendor service table and append one native row.
local Service=assert(loadfile('/usr/local/speedify-native/vendor-services.lua'))()
local _,collect=debug.getupvalue(Service.GET_TYPE_status,1)
assert(type(collect)=='function','Unexpected RutOS services implementation')
local ubus=require('ubus')
function Service:GET_TYPE_status()
 local rows=collect()
 local conn=ubus.connect();local state=conn and conn:call('speedify','status',{})
 if conn then conn:close() end
 local data=state and state.data or {}
 rows[#rows+1]={service='Speedify',enabled=data.bootEnabled and '1' or '0',status=data.online and 'Running' or (data.bootEnabled and 'Down' or 'Disabled'),path='/services/vpn/speedify'}
 return self:ResponseOK(rows)
end
return Service
