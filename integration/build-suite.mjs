// Assemble only a source-built native payload; the upstream preview is not used here.
import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {createRequire} from 'node:module';
import {spawnSync} from 'node:child_process';
const integration=path.dirname(new URL(import.meta.url).pathname).replace(/^\/([A-Za-z]:)/,'$1');
const source=path.resolve(process.argv[2]),native=path.resolve(process.argv[3]);
process.chdir(source);
const require=createRequire(path.join(source,'package.json')),version='0.5.0';
function run(command,args){const r=spawnSync(command,args,{stdio:'inherit',shell:process.platform==='win32'&&command!==process.execPath});if(r.status!==0)throw Error(command+' failed: '+r.status);}
for(const name of ['package.json','package-lock.json']){
 const p=path.join(source,name),j=JSON.parse(await fs.readFile(p,'utf8'));j.version=version;if(j.packages?.[''])j.packages[''].version=version;await fs.writeFile(p,JSON.stringify(j,null,2)+'\n');
}
run('npm',['run','build']);
run('npx',['electron-builder','--win','dir','--x64','--config.directories.output=release-0.5']);
const payload=path.join(source,'release-0.5/win-unpacked');
const PE=require('pe-library'),RE=require('resedit');
async function identity(input,output,name,iconName){
 const exe=PE.NtExecutable.from(await fs.readFile(input),{ignoreCert:true}),res=PE.NtExecutableResource.from(exe);
 const versions=RE.Resource.VersionInfo.fromEntries(res.entries);
 if(!versions.length)throw Error('Missing native version resource: '+input);
 for(const vi of versions){
  vi.setFileVersion(0,5,0,0,1033);vi.setProductVersion(0,5,0,0,1033);
  vi.setStringValues({lang:1033,codepage:1200},{FileDescription:name,ProductName:name,InternalName:name,OriginalFilename:path.basename(output),CompanyName:'Hasbreo'});vi.outputToResourceEntries(res.entries);
 }
 const icon=RE.Data.IconFile.from(await fs.readFile(path.join(source,'assets',iconName+'.ico')));
 RE.Resource.IconGroupEntry.replaceIconsForResource(res.entries,101,1033,icon.icons.map(i=>i.data));res.outputResource(exe);await fs.writeFile(output,Buffer.from(exe.generate()));
}
for(const name of ['WordFlow','CellFlow','SlideFlow','MailFlow','PDFFlow','OfficeFlowUpdater'])
 await identity(path.join(payload,'OfficeFlow.exe'),path.join(payload,name+'.exe'),name,name==='OfficeFlowUpdater'?'officeflow':name.toLowerCase());
await fs.cp(native,path.join(payload,'collabora'),{recursive:true});
for(const name of ['WordFlow','CellFlow','SlideFlow']){
 const p=path.join(payload,'collabora/program',name+'.exe');await identity(p,p,name,name.toLowerCase());
}
await fs.rm(path.join(payload,'collabora/program/OfficeFlow.exe'),{force:true});
await fs.writeFile(path.join(payload,'collabora/OFFICEFLOW-SOURCE.txt'),'OfficeFlow document editors use Collabora Online / LibreOffice technology.\nCorresponding pinned source and modifications: https://github.com/hasbreo/OfficeFlow\nComponent licences and attribution are retained in this directory.\n');
// Store Electron once in NSIS and reconstruct its six process identities.
const patches=path.join(source,'scripts/make-installer-patches.mjs');let text=await fs.readFile(patches,'utf8');
text=text.replace("'MailFlow','PDFFlow']","'MailFlow','PDFFlow','OfficeFlowUpdater']");await fs.writeFile(patches,text);
await fs.copyFile(path.join(integration,'installer.nsi'),path.join(source,'scripts/installer.nsi'));
let cleanup='';for(const [name,ext] of [['WordFlow','docx'],['CellFlow','xlsx'],['SlideFlow','pptx'],['MailFlow',''],['PDFFlow','pdf']]){
 cleanup+=`Delete "$SMPROGRAMS\\OfficeFlow\\${name}.lnk"\n`;
 if(ext)cleanup+=`DeleteRegKey HKCU "Software\\Classes\\OfficeFlow.${ext}"\nDeleteRegValue HKCU "Software\\Classes\\.${ext}\\OpenWithProgids" "OfficeFlow.${ext}"\n`;
}
await fs.writeFile('scripts/uninstall-shortcuts.nsh',cleanup);
const compiler=await require('app-builder-lib/out/toolsets/windows').getMakeNsisPath('0.0.0');Object.assign(process.env,compiler.env);
process.env.MAKENSIS=compiler.path;process.env.OFFICEFLOW_PAYLOAD=payload;process.env.OFFICEFLOW_INSTALLER=path.join(source,'release-0.5/OfficeFlow-Setup-'+version+'.exe');
await import(pathToFileURL(path.join(source,'scripts/native-installer.mjs')));
