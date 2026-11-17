<template>
  <tlt-form ref="speedifyForm" :model="form" custom-save sid="speedify" :title="$t('Speedify')">
    <tlt-form-item-switch v-model="form.enabled" :label="$t('Enable')" prop="enabled" @update:model-value="dirty = true" />
    <tlt-form-model-item :label="$t('Speedify status')" element-id="speedify-status">
      <tlt-dummy-value :value="statusText" :class="snapshot.state?.state === 'CONNECTED' ? 'success' : 'text-theme-text-danger'" />
    </tlt-form-model-item>
    <tlt-form-item-switch v-model="form.boot" :label="$t('Start service on boot')" prop="boot" :help="$t('Starts the management service. VPN auto-connect stays off after a restart.')" @update:model-value="dirty = true" />
    <tlt-form-item-select v-model="form.mode" :label="$t('Bonding mode')" prop="mode" :options="modeOptions" :help="$t('Speed combines capacity. Streaming balances reliability and speed. Redundant duplicates packets and uses more data.')" @update:model-value="dirty = true" />
    <tlt-form-item-select v-model="form.transport" :label="$t('Transport protocol')" prop="transport" :options="transportOptions" @update:model-value="dirty = true" />
    <tlt-form-model-item :label="$t('Default VPN route')" element-id="default-route">
      <tlt-dummy-value :value="snapshot.settings?.enableDefaultRoute ? $t('Enabled') : $t('Off')" />
    </tlt-form-model-item>
    <tlt-form-model-item :label="$t('VPN connection')" element-id="vpn-connection">
      <div class="sfy-actions" style="display:flex;align-items:center;flex-wrap:wrap;gap:16px">
        <tlt-button :disabled="busy || !snapshot.online || !networkAck" @click="connect">{{ $t('Connect') }}</tlt-button>
        <tlt-button :disabled="busy || !snapshot.online" @click="execute('disconnect')">{{ $t('Disconnect') }}</tlt-button>
      </div>
    </tlt-form-model-item>
    <tlt-form-item-switch v-model="networkAck" :label="$t('Prepare network for VPN')" prop="networkAck" :help="$t('Connect may create a Speedify interface and firewall zone, reload networking and enable the VPN default route. A valid Router License is required.')" />
    <div class="sfy-save" style="display:flex;justify-content:flex-end;padding:24px"><tlt-button :disabled="busy" @click="save">{{ $t('Save & Apply') }}</tlt-button></div>
  </tlt-form>
  <tlt-card :title="$t('Speedify account')">
    <div class="sfy-info" style="padding:8px 24px 24px;line-height:1.6">
      <p>{{ accountText }}</p>
      <p>{{ $t('Sign in with your individual Speedify account or the account holding your Router License. Complete sign-in on the official Speedify website using email, Google, Apple or your available enterprise sign-in method.') }}</p>
      <p>{{ $t('This device remains a router. An individual account must have a subscription that authorizes router use; this option does not convert a personal subscription into a Router License. Only one Speedify account can be active on this router at a time.') }}</p>
      <tlt-form-item-select v-model="accountKind" :label="$t('Sign-in option')" :options="accountOptions" @update:model-value="clearActivation" />
      <div class="sfy-actions" style="display:flex;align-items:center;flex-wrap:wrap;gap:16px">
        <tlt-button :disabled="busy || !snapshot.online || signedIn" @click="activate">{{ accountKind === 'individual' ? $t('Sign in to individual account') : $t('Activate Router License') }}</tlt-button>
        <tlt-button type="text" :disabled="busy" @click="refresh">{{ $t('Refresh status') }}</tlt-button>
        <a href="https://support.speedify.com/article/923-how-to-buy-a-router-license" target="_blank" rel="noopener noreferrer">{{ $t('Get a Router License') }} </a>
      </div>
      <p v-if="activationCode"><strong>{{ $t('Activation code') }}: {{ activationCode }}</strong></p>
      <p v-if="activationUrl"><a :href="activationUrl" target="_blank" rel="noopener noreferrer">{{ $t('Open Speedify sign-in') }} </a></p>
      <p v-if="activationUrl">{{ $t('After signing in, return here and select Refresh status. Your Speedify password never passes through this UI.') }}</p>
      <template v-if="signedIn">
        <tlt-form-item-switch v-model="logoutAck" :label="$t('Confirm account sign-out')" :help="$t('Signing out disconnects the VPN and clears the saved Speedify account session. Use this before switching accounts.')" />
        <tlt-button :disabled="busy || !logoutAck" @click="signout">{{ $t('Sign out of Speedify') }}</tlt-button>
      </template>
    </div>
  </tlt-card>
  <tlt-table id="speedify-connections" :title="$t('Connections')" :columns="columns" :data-source="connections" @refresh="refresh">
    <template #status="{ record }"><tlt-dummy-value :value="record.status" :class="record.up ? 'success' : 'text-theme-text-danger'" /></template>
    <template #priority="{ record }">
      <tlt-form-item-select v-if="record.adapter" v-model="priorities[record.device]" :label="''" :options="priorityOptions" :disabled="busy" @update:model-value="value => priority(record.device, value)" />
      <span v-else>-</span>
    </template>
  </tlt-table>
  <tlt-card :title="$t('WAN activity')">
    <div class="sfy-info" style="padding:8px 24px 24px;line-height:1.6"><p>{{ $t('Physical WAN traffic, including traffic outside Speedify. These counters do not measure bonded VPN throughput.') }}</p>
      <p>{{ $t('Download') }}: <strong>{{ rates.download }}</strong> | {{ $t('Upload') }}: <strong>{{ rates.upload }}</strong></p>
      <svg class="sfy-chart" width="100%" height="130" viewBox="0 0 900 100" role="img" :aria-label="$t('WAN download and upload history')"><path d="M0 25H900M0 50H900M0 75H900" class="sfy-grid" fill="none" stroke="currentColor" opacity="0.12"/><polyline :points="rxPoints" class="sfy-rx" fill="none" stroke="#589cf3" stroke-width="2.5"/><polyline :points="txPoints" class="sfy-tx" fill="none" stroke="#34b288" stroke-width="2.5"/></svg>
      <p class="sfy-muted">{{ $t('Last 5 minutes') }} | {{ $t('Updated') }} {{ updated }}</p>
    </div>
  </tlt-card>
</template>
<script>
export default {
  data() { return {
    snapshot: {}, form: {enabled:false,boot:false,mode:'streaming',transport:'auto'}, dirty:false, loaded:false, busy:false, networkAck:false, accountKind:'individual', logoutAck:false, activationCode:'', activationUrl:'', priorities:{}, linkRates:{}, timer:null, previous:null, samples:[], rates:{download:'-',upload:'-'}, updated:'-',
    accountOptions:[['individual','Individual Speedify account'],['router','Router License account']],
    modeOptions:[['streaming','Streaming'],['speed','Speed'],['redundant','Redundant']],
    transportOptions:[['auto','Automatic'],['udp','UDP'],['tcp','TCP'],['tcp-multi','TCP multiple sockets'],['https','HTTPS']],
    priorityOptions:[['automatic','Automatic'],['always','Always'],['secondary','Secondary'],['backup','Backup'],['never','Never']],
    columns:[{dataIndex:'name',title:this.$t('Connection')},{dataIndex:'device',title:this.$t('Interface')},{dataIndex:'status',title:this.$t('Status')},{dataIndex:'speedify',title:this.$t('Speedify adapter')},{dataIndex:'rx',title:this.$t('Download')},{dataIndex:'tx',title:this.$t('Upload')},{dataIndex:'priority',title:this.$t('Priority')}]
  }},
  computed:{
    statusText(){return this.snapshot.online?(this.snapshot.state?.state||'Ready').replaceAll('_',' '):this.$t('Stopped')},
    signedIn(){return !!this.snapshot.online && !!this.snapshot.state?.state && this.snapshot.state.state!=='LOGGED_OUT'},
    accountText(){return this.snapshot.user?.email|| (this.snapshot.state?.state==='LOGGED_OUT'?this.$t('No Speedify account is signed in.'):this.$t('Start the service or refresh status to check your Speedify account.'))},
    connections(){return (this.snapshot.links||[]).map(v=>{const modem=(this.snapshot.modems||[]).find(m=>m.name===v.name);const adapter=(this.snapshot.adapters||[]).find(a=>a.adapterID===v.device);return {...v,name:modem?.label||(v.name==='wan'?'Ethernet WAN':v.name),status:v.up?'Online':(modem?.sim||'Offline'),adapter,speedify:adapter?(adapter.ispType||adapter.type||'Detected'):'Not detected',rx:this.linkRates?.[v.device]?.rx||'-',tx:this.linkRates?.[v.device]?.tx||'-'}})},
    rxPoints(){return this.points(0)},txPoints(){return this.points(1)}
  },
  mounted(){this.refresh();this.timer=setInterval(()=>{if(!this.busy&&!document.hidden)this.refresh()},5000)},
  beforeUnmount(){clearInterval(this.timer)},
  methods:{
    rate(v){return v>=1e6?(v/1e6).toFixed(2)+' Mbps':(v/1000).toFixed(1)+' kbps'},
    points(index){const max=Math.max(1e5,...this.samples.flat());return Array.from({length:60},(_,i)=>{const v=this.samples[i-(60-this.samples.length)]?.[index]||0;return `${i*900/59},${95-v/max*90}`}).join(' ')},
    async refresh(){try{const {data:s}=await this.$axios.get('/api/speedify/status');this.snapshot=s;this.updated=new Date().toLocaleTimeString();if(!this.loaded||!this.dirty){this.form={enabled:s.online,boot:s.bootEnabled,mode:s.settings?.bondingMode||'streaming',transport:s.settings?.transportMode||'auto'}}this.loaded=true;
      (s.adapters||[]).forEach(a=>this.priorities[a.adapterID]=a.priority||'automatic');this.linkRates={};let rx=0,tx=0;
      if(this.previous&&s.time>this.previous.time){const dt=s.time-this.previous.time;(s.links||[]).forEach(v=>{const old=this.previous.links?.find(x=>x.device===v.device);if(old&&v.device){const r=Math.max(0,(v.rx-old.rx)*8/dt),t=Math.max(0,(v.tx-old.tx)*8/dt);rx+=r;tx+=t;this.linkRates[v.device]={rx:this.rate(r),tx:this.rate(t)}}});this.rates={download:this.rate(rx),upload:this.rate(tx)};this.samples.push([rx,tx]);this.samples=this.samples.slice(-60)}this.previous=s;
    }catch(e){this.$message.error(this.$t('Could not refresh Speedify status'))}},
    async command(action,extra={}){const {data}=await this.$axios.post('/api/speedify/actions/execute',{data:{action,...extra}});return data},
    async task(fn){if(this.busy)return;this.busy=true;try{await fn();await this.refresh();this.$message.success(this.$t('Speedify settings applied'))}catch(e){this.$message.error(e?.response?.data?.errors?.[0]?.error||this.$t('Speedify action failed. Check activation and service status.'))}finally{this.busy=false}},
    execute(action){return this.task(()=>this.command(action))},
    async save(){return this.task(async()=>{if(this.form.enabled&&!this.snapshot.online)await this.command('start');if(this.form.enabled)await this.command('preferences',{mode:this.form.mode,transport:this.form.transport});if(!this.form.enabled&&this.snapshot.online)await this.command('stop');await this.command('boot',{enabled:!!this.form.boot});this.dirty=false})},
    priority(id,value){return this.task(()=>this.command('priority',{id,value}))},
    connect(){return this.task(async()=>{await this.command('connect',{acknowledge:this.networkAck});this.networkAck=false})},
    clearActivation(){this.activationCode='';this.activationUrl=''},
    activate(){return this.task(async()=>{this.clearActivation();const result=await this.command('signin',{account:this.accountKind});this.activationCode=result?.activationCode||'';if(result?.activationUrl){const u=new URL(result.activationUrl);if(u.protocol==='https:'&&u.hostname==='my.speedify.com')this.activationUrl=u.href}})},
    signout(){return this.task(async()=>{await this.command('signout',{acknowledge:this.logoutAck});this.clearActivation();this.logoutAck=false;this.networkAck=false})}
  }
}
</script>
<style scoped>
.sfy-actions{display:flex;align-items:center;flex-wrap:wrap;gap:16px}.sfy-info{padding:8px 24px 24px}.sfy-info p{margin:12px 0;line-height:1.6}.sfy-save{display:flex;justify-content:flex-end;padding:24px}.sfy-chart{width:100%;height:130px;display:block;margin-top:16px}.sfy-grid{stroke:currentColor;opacity:.12;fill:none}.sfy-rx,.sfy-tx{fill:none;stroke-width:2.5;stroke:#589cf3}.sfy-tx{stroke:#34b288}.sfy-muted{opacity:.7;font-size:12px}
</style>
