#!/usr/bin/env python3
"""Build a private RutOS runtime from hash-pinned upstream artifacts. Python 3.11+."""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import tarfile
from verify_dependencies import MODULES, PLUGINS

SPEEDIFY_URL = 'https://downloads.speedify.com/speedify_arm_cortex-a7_neon-vfpv4.ipk'
SPEEDIFY_HASH = '15b19220ecedec1c4d84731e0d0d2e19fd41bdd45e15eda5d0262d616859ea08'
KEYUTILS_URL = 'https://deb.debian.org/debian/pool/main/k/keyutils/libkeyutils1_1.6.3-2_armhf.deb'
KEYUTILS_HASH = 'bfc6a3a668b58b88876b9e37192f669ceeb68db6d50c8374a9267a2bbd8f8a8e'
HERE = Path(__file__).resolve().parent

def checked(path, expected):
    data = Path(path).read_bytes()
    if hashlib.sha256(data).hexdigest() != expected:
        raise ValueError(f'SHA256 mismatch: {path}')
    return data

def ar_members(data):
    if not data.startswith(b'!<arch>\n'):
        raise ValueError('Not a Debian ar archive')
    pos = 8
    while pos < len(data):
        header = data[pos:pos+60]
        if len(header) != 60 or header[58:60] != b'`\n':
            raise ValueError('Invalid ar member')
        size = int(header[48:58])
        yield header[:16].decode().strip().rstrip('/'), data[pos+60:pos+60+size]
        pos += 60 + size + size % 2

def write_member(root, relative, data, mode=0o644):
    name = PurePosixPath(relative)
    if name.is_absolute() or '..' in name.parts:
        raise ValueError(f'Unsafe archive member: {relative}')
    dest = root.joinpath(*name.parts)
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)
    dest.chmod(mode)

def build(speedify, keyutils, destination, dependencies):
    # No upstream package maintainer scripts are executed or shipped.
    destination = destination.resolve()
    if destination.exists():
        raise ValueError('Build destination must not exist; use a fresh directory')
    ipk = checked(speedify, SPEEDIFY_HASH)
    deb = checked(keyutils, KEYUTILS_HASH)
    dependency_manifest = json.loads((dependencies/'dependencies.json').read_text())
    if dependency_manifest['firmware'] != 'RUTX_R_00.07.26.2' or dependency_manifest['kernel'] != '6.6.137':
        raise ValueError('Wrong dependency target')
    required={f'kmods/{name}.ko' for name in MODULES}|{f'plugins/libxt_{name}.so' for name in PLUGINS}|{'bin/native-probe'}
    if set(dependency_manifest['files']) != required:
        raise ValueError('Incomplete or unexpected dependency manifest')
    destination.mkdir(parents=True)
    with tarfile.open(fileobj=io.BytesIO(ipk)) as outer:
        payload = outer.extractfile('./data.tar.gz').read()
    with tarfile.open(fileobj=io.BytesIO(payload)) as data:
        prefix = 'usr/share/speedify/'
        for member in data.getmembers():
            name = member.name.removeprefix('./')
            if not name.startswith(prefix) or not member.isfile():
                continue
            relative = name[len(prefix):]
            # Deliberately omit upstream networking/reset/tether scripts.
            if relative in ('speedify', 'speedify_cli', 'cacert.pem') or relative.startswith('lib/arm-linux-gnueabihf/'):
                write_member(destination, 'runtime/'+relative, data.extractfile(member).read(), member.mode & 0o777)
    deb_payload = next(content for name, content in ar_members(deb) if name.startswith('data.tar.'))
    with tarfile.open(fileobj=io.BytesIO(deb_payload)) as data:
        lib = next(m for m in data.getmembers() if m.isfile() and m.name.endswith('/libkeyutils.so.1.10'))
        blob = data.extractfile(lib).read()
        # Regular copies also work on Windows build hosts. No global symlinks.
        for name in ('libkeyutils.so', 'libkeyutils.so.1', 'libkeyutils.so.1.10'):
            write_member(destination, 'runtime/lib/arm-linux-gnueabihf/'+name, blob, 0o755)
        for m in data.getmembers():
            if m.isfile() and m.name.endswith('/copyright'):
                write_member(destination, 'licenses/keyutils-copyright', data.extractfile(m).read())
    for src in (HERE/'files').rglob('*'):
        if src.is_file():
            relative = src.relative_to(HERE/'files').as_posix()
            write_member(destination, relative, src.read_bytes().replace(b'\r\n', b'\n'), 0o755 if relative.startswith(('bin/', 'init.d/')) else 0o644)
    for relative, expected in dependency_manifest['files'].items():
        checked_blob = checked(dependencies/relative, expected)
        write_member(destination, relative, checked_blob, 0o755 if relative.endswith('.so') or relative.startswith('bin/') else 0o644)
    write_member(destination, 'dependencies.json', (json.dumps(dependency_manifest, indent=2)+'\n').encode())
    manifest = {
        'port_version': '0.3.0', 'speedify_version': '17.3.0-12956',
        'firmware': 'RUTX_R_00.07.26.2', 'arch': 'cortexa7hf-neon-vfpv4',
        'kernel': '6.6.137', 'kernel_package': '6.6-r0',
        'vermagic': '6.6.137 SMP mod_unload ARMv7 p2v8',
        'upstream': {SPEEDIFY_URL: SPEEDIFY_HASH, KEYUTILS_URL: KEYUTILS_HASH},
        'status': 'firmware-specific port; see validation report for runtime and bonding results',
    }
    write_member(destination, 'manifest.json', (json.dumps(manifest, indent=2)+'\n').encode())
    files = sorted(p for p in destination.rglob('*') if p.is_file())
    checksums = ''.join(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.relative_to(destination).as_posix()}\n' for p in files)
    write_member(destination, 'SHA256SUMS', checksums.encode())
    archive = Path(str(destination)+'.tar.gz')
    with tarfile.open(archive, 'w:gz', format=tarfile.USTAR_FORMAT) as tar:
        for path in sorted(p for p in destination.rglob('*') if p.is_file()):
            info = tar.gettarinfo(str(path), 'speedify-rutos/'+path.relative_to(destination).as_posix())
            info.uid = info.gid = info.mtime = 0
            info.uname = info.gname = ''
            info.mode = 0o755 if path.relative_to(destination).parts[0] in ('bin','init.d') or path.name in ('speedify','speedify_cli') or '.so' in path.name else 0o644
            with path.open('rb') as stream:
                tar.addfile(info, stream)
    print(json.dumps({'archive': str(archive), 'sha256': hashlib.sha256(archive.read_bytes()).hexdigest(), 'files': len(files)}, indent=2))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--speedify', required=True, type=Path)
    parser.add_argument('--keyutils', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--dependencies', required=True, type=Path)
    args = parser.parse_args()
    build(args.speedify, args.keyutils, args.output, args.dependencies)
