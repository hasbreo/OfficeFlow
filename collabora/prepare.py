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
    if text not in (reference, patch_identity(reference)):
        raise ValueError('Refusing to overwrite other edits to CODA.cpp')
    source.write_text(patch_identity(text))
    return head

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('checkout', type=pathlib.Path)
    args = parser.parse_args()
    print('Prepared', prepare(args.checkout.resolve()))
