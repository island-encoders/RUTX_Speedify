-- Browser-based account sign-in. Device role and license checks stay unchanged.
local M={}
local function fail(message) return {ok=false,error=message} end
function M.signin(cli,kind)
 if kind~='individual' and kind~='router' then return fail('Choose an individual account or Router License account') end
 local state=cli('state')
 if not state or not state.state then return fail('Start the Speedify service first') end
 if state.state~='LOGGED_OUT' then return fail('Sign out of the current Speedify account before changing accounts') end
 -- Activation may initiate a connection. Keep route takeover and boot connect off.
 for _,args in ipairs({{'route','default','off'},{'startupconnect','off'}}) do
  local _,_,code=cli(unpack(args));if code~=0 then return fail('Could not prepare Speedify for sign-in') end
 end
 local result,_,code=cli('activationcode')
 if code~=0 or type(result)~='table' then return fail('Could not generate a Speedify sign-in code') end
 local url=result.activationUrl
 if type(url)~='string' or not url:match('^https://my%.speedify%.com/activate%?') or url:find('[%c%s#]') then return fail('Speedify returned an unexpected sign-in URL') end
 local role=url:match('[?&]role=([^&#]*)')
 if role and role~='router' then return fail('Unexpected device role in sign-in URL') end
 local _,roles=url:gsub('[?&]role=','');if roles>1 then return fail('Duplicate device role in sign-in URL') end
 if not role then url=url..'&role=router' end
 return {ok=true,data={activationCode=result.activationCode,activationUrl=url,account=kind}}
end
function M.signout(cli,acknowledge)
 if acknowledge~=true then return fail('Confirm sign-out: this disconnects the VPN and removes the saved Speedify account session') end
 for _,args in ipairs({{'disconnect'},{'route','default','off'},{'startupconnect','off'}}) do
  local _,_,code=cli(unpack(args));if code~=0 then return fail('Could not safely disconnect Speedify before sign-out') end
 end
 local result,_,code=cli('logout')
 if code~=0 then return fail('Speedify sign-out failed') end
 return {ok=true,data=result or {}}
end
return M
