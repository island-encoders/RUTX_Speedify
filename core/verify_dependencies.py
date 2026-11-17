#!/usr/bin/env python3
"""Validate locally built dependencies and write a hash manifest for bundling."""
import argparse
import hashlib
import json
from pathlib import Path
from compare_elf_sections import sections

MODULES=('sfy_udp_lookup','tcp_bbr','nf_tproxy_ipv4','nf_tproxy_ipv6','nf_socket_ipv4','nf_socket_ipv6','xt_TPROXY','xt_socket','xt_addrtype','xt_owner','xt_pkttype','xt_quota')
PLUGINS=('TPROXY','addrtype','socket','owner','pkttype','quota')
MAGIC='6.6.137 SMP mod_unload ARMv7 p2v8'

def validate(root,baseline):
    comparison=json.loads(baseline.read_text())
    if '.text' not in comparison or not all(r['equal'] for r in comparison.values()):
        raise ValueError('Stock baseline comparison did not pass')
    files={}
    module_info={}
    for name in MODULES:
        path=root/'kmods'/f'{name}.ko'
        sec=sections(path)
        info=dict(item.decode().split('=',1) for item in sec['.modinfo'].split(b'\0') if b'=' in item)
        if info.get('name')!=name or info.get('vermagic','').strip()!=MAGIC:
            raise ValueError(f'Wrong module identity or vermagic: {name}')
        module_info[name]={'vermagic':info['vermagic'].strip(),'depends':info.get('depends','')}
        files[path.relative_to(root).as_posix()]=hashlib.sha256(path.read_bytes()).hexdigest()
    for name in PLUGINS:
        path=root/'plugins'/f'libxt_{name}.so'
        sec=sections(path)
        if not sec.get('.text') or b'GLIBC_' in path.read_bytes():
            raise ValueError(f'Not a native musl plugin: {name}')
        if b'ARRAY_SIZE\0' in sec.get('.dynstr',b''):
            raise ValueError(f'Unresolved internal macro: {name}')
        files[path.relative_to(root).as_posix()]=hashlib.sha256(path.read_bytes()).hexdigest()
    cfg=(root/'kmods'/'kernel.config').read_text()
    probe=root/'bin'/'native-probe'
    if not sections(probe).get('.text'):
        raise ValueError('Native runtime probe is missing')
    files['bin/native-probe']=hashlib.sha256(probe.read_bytes()).hexdigest()
    compiler=next((line.split('=',1)[1].strip('"') for line in cfg.splitlines() if line.startswith('CONFIG_CC_VERSION_TEXT=')),'')
    allowed_compilers={'arm-poky-linux-musleabi-gcc (GCC) 13.4.0','arm-poky-linux-gnueabi-gcc (GCC) 13.4.0'}
    if compiler not in allowed_compilers or 'CONFIG_GCC_VERSION=130400' not in cfg:
        raise ValueError('Unexpected kernel compiler')
    if 'CONFIG_MODVERSIONS=y' in cfg:
        raise ValueError('Unexpected module versioning policy')
    record={'firmware':'RUTX_R_00.07.26.2','kernel':'6.6.137','kernel_package':'6.6-r0',
            'vermagic':MAGIC,'compiler':compiler+' / Teltonika 7.26.2 SDK',
            'iptables':'1.8.10 / libxtables.so.12.7.0',
            'baseline_sections_match':comparison,'modules':module_info,'files':files}
    (root/'dependencies.json').write_text(json.dumps(record,indent=2)+'\n')
    return record

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('root',type=Path)
    parser.add_argument('--baseline',required=True,type=Path)
    args=parser.parse_args()
    result=validate(args.root,args.baseline)
    print(f"Validated {len(result['files'])} native dependency files.")
