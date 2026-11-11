"""Apply the shared updater bridge to the checksum-pinned 0.4.3 source tree."""
from pathlib import Path
import argparse, shutil

def prepare(root):
    here=Path(__file__).resolve().parent
    target=root/'desktop/main.cjs'
    original=target.read_text()
    marker="// OfficeFlow native editor update bridge"
    if marker not in original:
        target.write_text(marker+"\nif (process.argv.includes('--update-helper')) {\n require('./update-helper.cjs').run();\n} else {\n"+original+"\n}\n")
    shutil.copyfile(here/'shared/update-helper.cjs',root/'desktop/update-helper.cjs')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('source',type=Path);a=p.parse_args();prepare(a.source.resolve())
