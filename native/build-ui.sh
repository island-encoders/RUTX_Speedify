#!/bin/bash
set -e
HERE=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cp "$HERE"/ui-build/* "$BUILD/"
cp "$HERE/Speedify.vue" "$BUILD/"
cd "$BUILD"
npm ci --ignore-scripts --no-audit --no-fund
printf 'VITE_PLUGIN_ENTRY=./Speedify.vue\nVITE_PLUGIN_FILENAME=plugin\n' >.env.pluginspeedify
./node_modules/.bin/vite build --outDir compiled --config vite.config.js --mode pluginspeedify
node - "$HERE" <<'JS'
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const root=process.argv[2],out='compiled';
const file=fs.readdirSync(out).find(x=>/^plugin\.(m?js)\.gz$/.test(x));
const bytes=fs.readFileSync(path.join(out,file));
const name='Speedify_'+crypto.createHash('sha256').update(bytes).digest('hex').slice(0,8);
const dest=path.join(root,'views/services');fs.mkdirSync(dest,{recursive:true});
for(const f of fs.readdirSync(dest))if(/^Speedify_[a-f0-9]+\.(js|css)\.gz$/.test(f))fs.unlinkSync(path.join(dest,f));
fs.writeFileSync(path.join(dest,name+'.js.gz'),bytes);
fs.copyFileSync(path.join(out,'style.css.gz'),path.join(dest,name+'.css.gz'));
const menu=JSON.parse(fs.readFileSync(path.join(root,'menu.json'),'utf8'));menu['services/vpn/speedify'].view='services/'+name;
fs.writeFileSync(path.join(root,'menu.json'),JSON.stringify(menu)+'\n');
function files(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(f=>f.isDirectory()?files(path.join(dir,f.name)):[path.join(dir,f.name)])}
const manifest=files(root).filter(f=>path.relative(root,f)!=='SHA256SUMS').sort().map(f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex')+'  '+path.relative(root,f).split(path.sep).join('/')+'\n').join('');
fs.writeFileSync(path.join(root,'SHA256SUMS'),manifest);console.log('Built',name);
JS
