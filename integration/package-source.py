"""Bundle corresponding shared source and the exact native build recipe, never keys/binaries."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import sys, json, subprocess
shared=Path(sys.argv[1]).resolve(); repo=Path(__file__).resolve().parent.parent
version=json.loads((shared/'package.json').read_text())['version']
output=shared.parent/f'OfficeFlow-{version}-source.zip'
def excluded(relative):
    return any(p in {'node_modules','.git','dist','test-results','playwright-report','__pycache__','build-deps'} or p.startswith('release') for p in relative.parts) or relative.suffix in {'.pem','.key'}
with ZipFile(output,'w',ZIP_DEFLATED) as archive:
    tracked=subprocess.check_output(['git','-C',str(repo),'ls-files','-z']).decode().split('\0')
    sources=[(shared,Path('OfficeFlow'),shared.rglob('*')),(repo,Path('OfficeFlow/native-build'),(repo/p for p in tracked if p))]
    for source,prefix,paths in sources:
        for p in paths:
            r=p.relative_to(source)
            if not p.is_file() or excluded(r) or r.parts[:2] in [('public','fonts'),('public','pdfjs'),('public','mupdf'),('scripts','app-patches')]: continue
            archive.write(p,prefix/r)
print(output)
