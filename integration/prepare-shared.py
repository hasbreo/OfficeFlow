"""Apply the shared updater bridge to the checksum-pinned 0.4.3 source tree."""
from pathlib import Path
import argparse, shutil

def prepare(root):
    here=Path(__file__).resolve().parent
    shutil.copyfile(here/'README.release.md',root/'README.md')
    target=root/'desktop/main.cjs'
    original=target.read_text()
    marker="// OfficeFlow native editor update bridge"
    if original.startswith(marker):
        original=original.split('} else {\n',1)[1].removesuffix('\n}\n')
    if not original.startswith('// Keep the existing MailFlow/PDFFlow profile;'):
        original=original.replace('updater.check(win,true)','launchUpdateHelper(false)').replace('updater.check(win,false)','launchUpdateHelper(true)')
        original=original.replace('Powered by BetterOffice and open-source components.','Document editors powered by Collabora. See the included open-source notices.')
        original='''function launchUpdateHelper(startup){
 const path=require('node:path');
 const child=require('node:child_process').spawn(path.join(path.dirname(process.execPath),'OfficeFlowUpdater.exe'),['--update-helper',...(startup?['--startup']:[])],{detached:true,stdio:'ignore'});
 child.once('spawn',()=>child.unref());child.once('error',error=>console.error('Updater:',error.message));
}
'''+original
        (root/'desktop/legacy-main.cjs').write_text(original)
    for name in ['electron-entry.cjs','update-helper.cjs','download-verified.cjs']:
        shutil.copyfile(here/'shared'/name,root/'desktop'/('main.cjs' if name=='electron-entry.cjs' else name))
    updates=root/'desktop/updates.cjs';text=updates.read_text()
    start='const bytes=Buffer.from(await download.arrayBuffer());';end='await atomicWrite(target,bytes);'
    if start in text:
        a=text.index(start);b=text.index(end,a)+len(end)
        text=text[:a]+'''const target=path.join(this.app.getPath('temp'),`OfficeFlow-Setup-${m.version}.exe`);await require('./download-verified.cjs').downloadVerified(download,m,target);'''+text[b:]
        text=text.replace('AbortSignal.timeout(300000)','AbortSignal.timeout(1800000)');updates.write_text(text)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('source',type=Path);a=p.parse_args();prepare(a.source.resolve())
