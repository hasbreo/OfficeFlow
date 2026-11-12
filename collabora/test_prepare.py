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

    def test_native_ui_patch_is_repeatable_and_uses_office_formats(self):
        original = (root / 'upstream-reference/CODA.cpp').read_text()
        patched = module.patch_native_ui(original)
        self.assertEqual(patched, module.patch_native_ui(patched))
        self.assertIn('&officeflowApp=', patched)
        self.assertIn('data->mode == DocumentMode::WELCOME ? "&startreadonly=true"', patched)
        for ext in ['docx', 'xlsx', 'pptx']:
            self.assertIn('templateExtension = L"' + ext + '";', patched)

    def test_start_pages_keep_only_the_app_document_family(self):
        original = (root / 'upstream-reference/Control.BackstageView.ts').read_text()
        patched = module.patch_backstage(original)
        self.assertEqual(patched, module.patch_backstage(patched))
        self.assertIn('officeFlowType', patched)
        for action in ['executePrint()', 'executeSave()', 'executeSaveAs()', 'executeOptions()']:
            self.assertEqual(original.count(action), patched.count(action))

    def test_native_nasm_paths_preserve_windows_output(self):
        original = '$(call gb_Helper_wsl_path,$(NASM) $(T_NASMFLAGS) test.asm -o $@)'
        patched = module.patch_nasm_paths(original)
        self.assertIn('gb_Helper_nasm_path',patched)
        self.assertEqual(patched,module.patch_nasm_paths(patched))
        self.assertIn('$(if $(WSL),',patched)
        with self.assertRaises(ValueError): module.patch_nasm_paths('unexpected rule')

    def test_branding_matches_upstream_copy_contract(self):
        # Upstream unconditionally copies images/*.svg and this toolbar asset.
        brand = root / 'branding'
        self.assertTrue((brand / 'images/toolbar-bg-logo.svg').is_file())
        self.assertTrue(list((brand / 'images').glob('*.svg')))
        css = (brand / 'branding.css').read_text()
        self.assertIn("url('branding-officeflow.svg')", css)
        self.assertTrue((brand / 'branding-officeflow.svg').is_file())

    def test_blank_packages_are_valid_office_files(self):
        import zipfile
        for filename, part in [('TextDocument.docx','word/document.xml'),('Spreadsheet.xlsx','xl/workbook.xml'),('Presentation.pptx','ppt/presentation.xml')]:
            with zipfile.ZipFile(root / 'templates' / filename) as package:
                self.assertIn(part, package.namelist())
                self.assertIn('[Content_Types].xml', package.namelist())

if __name__ == '__main__':
    unittest.main()
