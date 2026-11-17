local Service=require('api/FunctionService'):new()
local ubus=require('ubus')
local json=require('luci.jsonc')
local function call(method,args)
 local c=ubus.connect();if not c then return nil end
 local result=c:call('speedify',method,args or {});c:close();return result
end
function Service:respond(result)
 if not result or not result.ok then self:add_critical_error(100,result and result.error or 'Speedify controller unavailable','speedify');return self:ResponseError() end
 return self:ResponseOK(result.data)
end
function Service:GET_TYPE_status() return self:respond(call('status')) end
function Service:Execute() return self:respond(call('command',{payload=json.stringify(self.arguments.data or {})})) end
local action=Service:action('execute',Service.Execute)
for _,key in ipairs({'action','value','id','mode','transport','account'}) do local field=action:option(key);field.maxlength=160;if key=='action' then field.require=true end end
action:option('acknowledge')
action:option('enabled')
return Service
