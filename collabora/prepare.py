"""Prepare a pinned Collabora checkout. Never edits the installed OfficeFlow."""
import argparse, hashlib, json, pathlib, subprocess

ROOT = pathlib.Path(__file__).resolve().parent
LOCK = json.loads((ROOT / 'upstream.lock.json').read_text())

def patch_identity(text):
    marker = '// OfficeFlow native process identity'
    if marker in text:
        return text
    declaration = 'static std::wstring appName;'
    startup = '    appName = Util::string_to_wide_string(APP_NAME);'
    if text.count(declaration) != 1 or text.count(startup) != 1:
        raise ValueError('Upstream startup changed; review the patch before building')
    # Adjacent C++ string literals must become a normal string expression.
    text = text.replace('tab.filenameAndUri.filename + " - " APP_NAME',
                        'tab.filenameAndUri.filename + " - " + officeFlowAppName')
    text = text.replace('Util::string_to_wide_string(APP_NAME)',
                        'Util::string_to_wide_string(officeFlowAppName)')
    text = text.replace(declaration, declaration + '\n' + marker +
                        '\nstatic std::string officeFlowAppName = "OfficeFlow";')
    text = text.replace('    appName = Util::string_to_wide_string(officeFlowAppName);', '''    // Each executable has its own taskbar identity, profile and native titles.
    const auto officeFlowExecutable = std::filesystem::path(fileName).stem().wstring();
    if (_wcsicmp(officeFlowExecutable.c_str(), L"WordFlow") == 0)
        officeFlowAppName = "WordFlow";
    else if (_wcsicmp(officeFlowExecutable.c_str(), L"CellFlow") == 0)
        officeFlowAppName = "CellFlow";
    else if (_wcsicmp(officeFlowExecutable.c_str(), L"SlideFlow") == 0)
        officeFlowAppName = "SlideFlow";
    appName = Util::string_to_wide_string(officeFlowAppName);''')
    return text

def prepare(checkout):
    head = subprocess.check_output(['git', '-C', str(checkout), 'rev-parse', 'HEAD'], text=True).strip()
    if head != LOCK['commit']:
        raise ValueError('Checkout does not match upstream.lock.json')
    source = checkout / 'windows/coda/CODA/CODA.cpp'
    text = source.read_text()
    reference = (ROOT / 'upstream-reference/CODA.cpp').read_text()
    if text not in (reference, patch_native_ui(reference)):
        raise ValueError('Refusing to overwrite other edits to CODA.cpp')
    source.write_text(patch_native_ui(text))
    backstage = checkout / 'browser/src/control/Control.BackstageView.ts'
    original = (ROOT / 'upstream-reference/Control.BackstageView.ts').read_text()
    current = backstage.read_text()
    if current not in (original, patch_backstage(original)):
        raise ValueError('Refusing to overwrite other edits to BackstageView')
    backstage.write_text(patch_backstage(current))
    return head

def patch_native_ui(text):
    native = patch_identity(text)
    if '&officeflowApp=' not in native:
        needle = '                        coolURL += "&lang=" + uiLanguage;'
        if native.count(needle) != 1:
            raise ValueError('Upstream document URL changed')
        native = native.replace(needle, '                        coolURL += "&officeflowApp=" + officeFlowAppName;\n' + needle)
    for old, new in [('odt', 'docx'), ('ods', 'xlsx'), ('odp', 'pptx')]:
        needle = 'templateExtension = L"' + old + '";'
        replacement = 'templateExtension = L"' + new + '";'
        if replacement not in native:
            if native.count(needle) != 1:
                raise ValueError('Upstream blank document template changed')
            native = native.replace(needle, replacement)
    return native

def patch_backstage(text):
    marker = '// OfficeFlow keeps each application on its own document family.'
    if marker in text:
        return text
    anchor = 'class BackstageView extends window.L.Class {'
    if text.count(anchor) != 1:
        raise ValueError('Upstream BackstageView changed')
    text = text.replace(anchor, anchor + '''
    // OfficeFlow keeps each application on its own document family.
    private readonly officeFlowType: TemplateType | null =
        ({WordFlow: 'writer', CellFlow: 'calc', SlideFlow: 'impress'} as Record<string, TemplateType>)[
            new URLSearchParams(window.location.search).get('officeflowApp') || ''
        ] || null;
''')
    blank = "\t\t\t\t\tthis.getBlankTemplate('draw'),\n\t\t\t\t],"
    if text.count(blank) != 1:
        raise ValueError('Upstream home template list changed')
    text = text.replace(blank, "\t\t\t\t\tthis.getBlankTemplate('draw'),\n\t\t\t\t].filter(t => t && (!this.officeFlowType || t.type === this.officeFlowType)),")
    types = "return (['writer', 'calc', 'impress', 'draw'] as TemplateType[]).map("
    if text.count(types) != 1:
        raise ValueError('Upstream new document types changed')
    text = text.replace(types, "return (['writer', 'calc', 'impress', 'draw'] as TemplateType[]).filter(t => !this.officeFlowType || t === this.officeFlowType).map(")
    text = text.replace('.filter(Boolean);', '.filter(Boolean)\n            .filter(t => !this.officeFlowType || t.type === this.officeFlowType);')
    condition = "(this.templateFilter === 'all' ||"
    if text.count(condition) != 1:
        raise ValueError('Upstream template filtering changed')
    return text.replace(condition, "(!this.officeFlowType || template.type === this.officeFlowType) &&\n                " + condition)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('checkout', type=pathlib.Path)
    args = parser.parse_args()
    print('Prepared', prepare(args.checkout.resolve()))
