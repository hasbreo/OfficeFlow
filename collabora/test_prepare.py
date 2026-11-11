import importlib.util, pathlib, unittest
root = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('prepare', root / 'prepare.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class NativeIdentityPatch(unittest.TestCase):
    def test_pinned_source_patch_is_idempotent(self):
        original = (root / 'upstream-reference/CODA.cpp').read_text()
        patched = module.patch_identity(original)
        self.assertEqual(patched, module.patch_identity(patched))
        for name in ['WordFlow', 'CellFlow', 'SlideFlow']:
            self.assertIn('officeFlowAppName = "' + name + '";', patched)
        self.assertIn(' + " - " + officeFlowAppName', patched)
        # Native profile isolation remains upstream's appName-based path.
        self.assertIn('L"\\\\" + appName', patched)
        self.assertIn('createDocumentView(tab.tabId)', patched)

    def test_changed_upstream_fails_closed(self):
        with self.assertRaises(ValueError):
            module.patch_identity('unrecognised startup implementation')

if __name__ == '__main__':
    unittest.main()
