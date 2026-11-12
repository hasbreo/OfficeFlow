"""Create a signed release and approved upload parts after candidate tests pass."""
from pathlib import Path
import argparse,hashlib,json,base64
from cryptography.hazmat.primitives.serialization import load_pem_private_key
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
def describe(path,kind,version):
    sha=hashlib.sha256();parts=[];size=0
    with path.open('rb') as stream:
        while chunk:=stream.read(8*1024*1024):
            size+=len(chunk);sha.update(chunk);parts.append({'size':len(chunk),'sha256':hashlib.sha256(chunk).hexdigest()})
    return {'filename':path.name,'size':size,'sha256':sha.hexdigest(),'type':'application/zip' if kind=='source' else 'application/vnd.microsoft.portable-executable','parts':parts}
def prepare(installer,source,key,site,output):
    version='0.5.0'
    assert installer.name==f'OfficeFlow-Setup-{version}.exe' and source.name==f'OfficeFlow-{version}-source.zip'
    files={k:describe(p,k,version) for k,p in [('installer',installer),('source',source)]}
    assert 0<files['installer']['size']<=1024**3,'Installer exceeds the existing updater limit'
    manifest={'version':version,'url':'https://hasbreo.com/downloads/officeflow/'+installer.name,'sha256':files['installer']['sha256'],'size':files['installer']['size'],'notes':'WordFlow, CellFlow and SlideFlow now use the full local Collabora desktop engine. Independent native apps, mint theme, Office file editing, PDF export, bundled printing runtime and shared signed updates. MailFlow and PDFFlow keep their existing data.'}
    private=load_pem_private_key(key.read_bytes(),password=None)
    assert isinstance(private,Ed25519PrivateKey)
    raw=json.dumps(manifest,separators=(',',':'),ensure_ascii=False).encode()
    manifest['signature']=base64.b64encode(private.sign(raw)).decode()
    release={'version':version,'manifest':manifest,'files':files}
    worker=site/'worker/officeflow-downloads.mjs';lines=worker.read_text().splitlines()
    prefix='export const OFFICEFLOW_RELEASE = ';previous='const OFFICEFLOW_PREVIOUS_RELEASES = '
    assert lines[0].startswith(prefix) and lines[1].startswith(previous)
    old=json.loads(lines[0][len(prefix):].removesuffix(';'))
    history=json.loads(lines[1][len(previous):].removesuffix(';'))
    if old['version']!=version:history=[old]+[r for r in history if r['version']!=old['version']]
    lines[0]=prefix+json.dumps(release,separators=(',',':'))+';'
    lines[1]=previous+json.dumps(history,separators=(',',':'))+';'
    worker.write_text('\n'.join(lines)+'\n')
    output.write_text(json.dumps(release,indent=2)+'\n')
    print('Prepared signed release',version,'installer bytes',files['installer']['size'])
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('installer',type=Path);p.add_argument('source',type=Path);p.add_argument('key',type=Path);p.add_argument('site',type=Path);p.add_argument('output',type=Path);a=p.parse_args();prepare(a.installer,a.source,a.key,a.site,a.output)
