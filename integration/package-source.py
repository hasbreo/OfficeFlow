"""Bundle corresponding shared source and the exact native build recipe, never keys/binaries."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import sys, json
shared=Path(sys.argv[1]).resolve(); repo=Path(__file__).resolve().parent.parent
version=json.loads((shared/'package.json').read_text())['version']
output=shared.parent/f'OfficeFlow-{version}-source.zip'
def excluded(relative):
    return any(p in {'node_modules','.git','dist','test-results','playwright-report','__pycache__','build-deps'} or p.startswith('release') for p in relative.parts) or relative.suffix in {'.pem','.key'}
with ZipFile(output,'w',ZIP_DEFLATED) as archive:
    for source,prefix in [(shared,Path('OfficeFlow')),(repo,Path('OfficeFlow/native-build'))]:
        for p in source.rglob('*'):
            r=p.relative_to(source)
            if not p.is_file() or excluded(r) or r.parts[:2] in [('public','fonts'),('public','pdfjs'),('public','mupdf')]: continue
            archive.write(p,prefix/r)
print(output)
