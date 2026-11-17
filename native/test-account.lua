local Account=assert(loadfile('account.lua'))()
local function fake(options)
 options=options or {};local calls={}
 local function cli(...)
  local args={...};calls[#calls+1]=table.concat(args,' ')
  if args[1]=='state' then if options.offline then return nil,'offline',1 end;return {state=options.state or 'LOGGED_OUT'},'',0 end
  if options.fail==calls[#calls] then return nil,'failure',1 end
  if args[1]=='activationcode' then return {activationCode='123456',activationUrl=options.url or 'https://my.speedify.com/activate?activationCode=123456&role=router'},'',0 end
  return {state='LOGGED_OUT'},'',0
 end
 return cli,calls
end
for _,kind in ipairs({'individual','router'}) do
 local cli,calls=fake();local r=Account.signin(cli,kind)
 assert(r.ok and r.data.account==kind and r.data.activationUrl:find('role=router',1,true))
 assert(table.concat(calls,';')=='state;route default off;startupconnect off;activationcode')
end
do local c,calls=fake();assert(not Account.signin(c,'client').ok and #calls==0) end
do local c,calls=fake({state='CONNECTED'});assert(not Account.signin(c,'individual').ok and #calls==1) end
do local c,calls=fake({offline=true});assert(not Account.signin(c,'individual').ok and #calls==1) end
do local c=fake({fail='route default off'});assert(not Account.signin(c,'individual').ok) end
do local c=fake({fail='startupconnect off'});assert(not Account.signin(c,'individual').ok) end
do local c=fake({fail='activationcode'});assert(not Account.signin(c,'individual').ok) end
for _,url in ipairs({'http://my.speedify.com/activate?activationCode=1','https://my.speedify.com.evil/activate?activationCode=1','https://evil.com/activate?activationCode=1','https://my.speedify.com/activate?role=client','https://my.speedify.com/activate?role=router&role=client','https://my.speedify.com/activate?activationCode=1#role=router'}) do
 local c=fake({url=url});assert(not Account.signin(c,'individual').ok)
end
do local c=fake({url='https://my.speedify.com/activate?activationCode=123456'});assert(Account.signin(c,'individual').data.activationUrl:find('&role=router',1,true)) end
do local c,calls=fake();assert(not Account.signout(c,false).ok and #calls==0) end
do local c,calls=fake();assert(Account.signout(c,true).ok);assert(table.concat(calls,';')=='disconnect;route default off;startupconnect off;logout') end
do local c=fake({fail='disconnect'});assert(not Account.signout(c,true).ok) end
do local c=fake({fail='logout'});assert(not Account.signout(c,true).ok) end
print('PASS: individual/router browser sign-in, role preservation, URL restrictions, explicit sign-out and failure handling')
