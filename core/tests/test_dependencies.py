import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
import build_port
import verify_dependencies

class DependencyTests(unittest.TestCase):
    # Tests use the actual built module ELF files, not fabricated module headers.
    original=None

    def setUp(self):
        if self.original is None:
            self.skipTest('Pass the built-dependencies directory as the first argument')
        self.temporary=tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.dep=Path(self.temporary.name)/'dependencies'
        shutil.copytree(self.original,self.dep)
        self.baseline=ROOT/'BASELINE-COMPARISON.json'

    def test_real_build_passes(self):
        result=verify_dependencies.validate(self.dep,self.baseline)
        self.assertEqual(len(result['files']),19)

    def test_wrong_kernel_module_rejected(self):
        path=self.dep/'kmods'/'tcp_bbr.ko'
        blob=path.read_bytes()
        self.assertIn(b'vermagic=6.6.137',blob)
        path.write_bytes(blob.replace(b'vermagic=6.6.137',b'vermagic=6.6.138',1))
        with self.assertRaisesRegex(ValueError,'vermagic'):
            verify_dependencies.validate(self.dep,self.baseline)

    def test_wrong_native_plugin_architecture_rejected(self):
        path=self.dep/'plugins'/'libxt_TPROXY.so'
        blob=bytearray(path.read_bytes())
        blob[18:20]=(183).to_bytes(2,'little')
        path.write_bytes(blob)
        with self.assertRaisesRegex(ValueError,'ELF32'):
            verify_dependencies.validate(self.dep,self.baseline)

    def test_failed_stock_comparison_rejected(self):
        baseline=Path(self.temporary.name)/'comparison.json'
        baseline.write_text(json.dumps({'.text':{'equal':False}}))
        with self.assertRaisesRegex(ValueError,'baseline comparison'):
            verify_dependencies.validate(self.dep,baseline)

    def test_modified_input_hash_rejected(self):
        path=self.dep/'kmods'/'tcp_bbr.ko'
        with self.assertRaisesRegex(ValueError,'SHA256 mismatch'):
            build_port.checked(path,'0'*64)

if __name__=='__main__':
    DependencyTests.original=Path(sys.argv.pop(1)).resolve() if len(sys.argv)>1 else None
    unittest.main()
