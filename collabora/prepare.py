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
    types = checkout / 'browser/src/control/backstage/Types.ts'
    original_types = (ROOT / 'upstream-reference/Types.ts').read_text()
    current_types = types.read_text()
    patched_types = original_types.replace("\t\t| 'quit';", "\t\t| 'checkupdates'\n\t\t| 'quit';")
    if current_types not in (original_types, patched_types):
        raise ValueError('Refusing to overwrite other edits to backstage types')
    types.write_text(patched_types)
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
    if '// OfficeFlow signed update bridge' not in native:
        declaration = 'static std::string officeFlowAppName = "OfficeFlow";'
        native = native.replace(declaration, declaration + '\nstatic void launchOfficeFlowUpdater(bool startup);')
        entry = 'int APIENTRY wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int showWindowMode)'
        if native.count(entry) != 1:
            raise ValueError('Upstream Windows entry point changed')
        helper = '''// OfficeFlow signed update bridge: only a fixed installed executable is launched.
static void launchOfficeFlowUpdater(bool startup)
{
    const auto helper = (std::filesystem::path(Util::string_to_wide_string(app_installation_path)) /
                         L".." / L".." / L"OfficeFlowUpdater.exe").lexically_normal();
    if (!std::filesystem::exists(helper))
    {
        if (!startup)
            MessageBoxW(nullptr, L"The updater is not included in this development build.",
                        L"OfficeFlow Updates", MB_OK | MB_ICONINFORMATION);
        return;
    }
    const wchar_t* flags = startup ? L"--update-helper --startup" : L"--update-helper";
    const auto result = reinterpret_cast<INT_PTR>(ShellExecuteW(
        nullptr, L"open", helper.c_str(), flags, helper.parent_path().c_str(), SW_SHOWNORMAL));
    if (result <= 32 && !startup)
        MessageBoxW(nullptr, L"Unable to start the OfficeFlow updater.",
                    L"OfficeFlow Updates", MB_OK | MB_ICONERROR);
}

'''
        native = native.replace(entry, helper + entry)
        command = '        else if (s.starts_with(L"newdoc "))'
        if native.count(command) != 1:
            raise ValueError('Upstream native message handling changed')
        native = native.replace(command, '''        else if (s == L"OFFICEFLOWCHECKUPDATES")
        {
            launchOfficeFlowUpdater(false);
        }
''' + command)
        loop = '    MSG msg;\n    while (GetMessage(&msg, NULL, 0, 0))'
        if native.count(loop) != 1:
            raise ValueError('Upstream native event loop changed')
        native = native.replace(loop, '    launchOfficeFlowUpdater(true);\n\n' + loop)
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
    action = '\t\topen: () => this.executeOpen(),'
    if text.count(action) != 1:
        raise ValueError('Upstream File actions changed')
    text = text.replace(action, action + "\n        checkupdates: () => window.postMobileMessage('OFFICEFLOWCHECKUPDATES'),")
    tabs = '\tprivate getTabsConfig(): BackstageTabConfig[] {\n\t\treturn ['
    if text.count(tabs) != 1:
        raise ValueError('Upstream File menu changed')
    text = text.replace(tabs, tabs + '''
            { id: 'officeflow-updates', label: _('Check for updates'), type: 'action',
              actionType: 'checkupdates', icon: 'lc_reload.svg', visible: true },''')
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
