#!/usr/bin/env python3
"""Compare selected executable sections of an ELF32 ARM module, ignoring debug data."""
import argparse
import hashlib
import json
from pathlib import Path
import struct

def sections(path):
    blob=Path(path).read_bytes()
    if blob[:6]!=b'\x7fELF\x01\x01' or struct.unpack_from('<H',blob,18)[0]!=40:
        raise ValueError('Expected ELF32 little-endian ARM')
    offset=struct.unpack_from('<I',blob,32)[0]
    size,count,names_index=struct.unpack_from('<HHH',blob,46)
    headers=[struct.unpack_from('<IIIIIIIIII',blob,offset+i*size) for i in range(count)]
    names_header=headers[names_index]
    names=blob[names_header[4]:names_header[4]+names_header[5]]
    result={}
    for h in headers:
        name=names[h[0]:].split(b'\0',1)[0].decode()
        if h[1]!=8:
            result[name]=blob[h[4]:h[4]+h[5]]
    return result

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('stock',type=Path)
    parser.add_argument('built',type=Path)
    args=parser.parse_args()
    a,b=sections(args.stock),sections(args.built)
    selected=['.text','.init.text','.exit.text','.rodata']
    records={}
    for name in selected:
        if name not in a and name not in b:
            continue
        records[name]={'stock_bytes':len(a.get(name,b'')),'built_bytes':len(b.get(name,b'')),
                       'equal':a.get(name)==b.get(name),
                       'stock_sha256':hashlib.sha256(a.get(name,b'')).hexdigest(),
                       'built_sha256':hashlib.sha256(b.get(name,b'')).hexdigest()}
    print(json.dumps(records,indent=2))
    raise SystemExit(0 if records and all(r['equal'] for r in records.values()) else 1)
