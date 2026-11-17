import assert from 'node:assert/strict';
import fs from 'node:fs';
const source=fs.readFileSync(new URL('Speedify.vue',import.meta.url),'utf8');
const script=source.match(/<script>([\s\S]*?)<\/script>/)[1];
const {default:component}=await import('data:text/javascript;base64,'+Buffer.from(script).toString('base64'));
const ctx={...component.data.call({$t:s=>s}),...component.methods};
const calls=[];
ctx.task=fn=>fn();
ctx.command=async(action,body)=>{calls.push({action,body});return {activationCode:'123456',activationUrl:'https://my.speedify.com/activate?activationCode=123456&role=router'}};
for(const account of ['individual','router']){
 ctx.accountKind=account;await ctx.activate();
 assert.deepEqual(calls.at(-1),{action:'signin',body:{account}});
 assert.equal(ctx.activationCode,'123456');
 assert.equal(new URL(ctx.activationUrl).searchParams.get('role'),'router');
}
ctx.logoutAck=true;ctx.networkAck=true;await ctx.signout();
assert.deepEqual(calls.at(-1),{action:'signout',body:{acknowledge:true}});
assert.equal(ctx.activationUrl,'');assert.equal(ctx.activationCode,'');
assert.equal(ctx.logoutAck,false);assert.equal(ctx.networkAck,false);
assert.equal(component.computed.signedIn.call({snapshot:{online:true,state:{state:'LOGGED_OUT'}}}),false);
assert.equal(component.computed.signedIn.call({snapshot:{online:true,state:{state:'LOGGED_IN'}}}),true);
assert.equal(component.computed.signedIn.call({snapshot:{online:false}}),false);
ctx.command=async()=>({activationCode:'123',activationUrl:'https://example.com/activate'});
await ctx.activate();assert.equal(ctx.activationUrl,'');
assert(!source.includes('type="password"'));
console.log('PASS: UI sign-in choices, command payloads, account state, URL filtering and sign-out cleanup');
