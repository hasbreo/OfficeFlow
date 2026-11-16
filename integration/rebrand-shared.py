"""Visible HasOffice identity; keep existing storage, OAuth and protocol identifiers."""
from pathlib import Path
import shutil
NAMES={'WordFlow':'HasWord','CellFlow':'HasCell','SlideFlow':'HasSlides','MailFlow':'HasMail','PDFFlow':'HasPDF','OfficeFlow':'HasOffice'}
def apply(root):
    # Profile paths, archive formats, encryption and protocol identifiers stay stable.
    for folder in ['src','desktop']:
        for p in (root/folder).rglob('*'):
            if p.suffix not in {'.js','.jsx','.cjs','.css','.html'}:continue
            text=p.read_text()
            for old,new in NAMES.items():text=text.replace(old,new)
            if p.name=='launch.cjs':
                text=text.replace('const executableKinds={',"const executableKinds={hasword:'word',hascell:'cell',hasslides:'slide',hasmail:'mail',haspdf:'pdf',")
            # Preserve the existing backup subfolder so subsequent backups stay together.
            text=text.replace('HasOffice-Mail','OfficeFlow-Mail')
            p.write_text(text)
    for old,new in NAMES.items():
        for suffix in ['.png','.ico']:
            source=root/'assets'/(old.lower()+suffix)
            if source.exists():shutil.copyfile(source,root/'assets'/(new.lower()+suffix))
    for icon in (Path(__file__).parent/'icons').glob('*'):
        if icon.suffix in {'.ico','.png'}:shutil.copyfile(icon,root/'assets'/icon.name)
    for suffix in ['.ico','.png']:
        shutil.copyfile(Path(__file__).parent/'icons'/('hasoffice'+suffix),root/'assets'/('officeflow'+suffix))
    import json
    p=root/'package.json';data=json.loads(p.read_text());data['productName']='HasOffice';data['build']['productName']='HasOffice';data['build']['nsis']['artifactName']='HasOffice-Setup-${version}.exe';
    for association in data['build'].get('fileAssociations',[]):
        for old,new in NAMES.items():association['name']=association.get('name','').replace(old,new)
    p.write_text(json.dumps(data,indent=2)+'\n')
