// Assemble only a source-built native payload; the upstream preview is not used here.
import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL,fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
import {spawnSync} from 'node:child_process';
const integration=path.dirname(fileURLToPath(import.meta.url));
const source=path.resolve(process.argv[2]),native=path.resolve(process.argv[3]);
process.chdir(source);
const require=createRequire(path.join(source,'package.json')),version='0.5.2';
function run(command,args){const r=spawnSync(command,args,{stdio:'inherit',shell:process.platform==='win32'&&command!==process.execPath});if(r.status!==0)throw Error(command+' failed: '+r.status);}
for(const name of ['package.json','package-lock.json']){
 const p=path.join(source,name),j=JSON.parse(await fs.readFile(p,'utf8'));j.version=version;if(j.packages?.[''])j.packages[''].version=version;await fs.writeFile(p,JSON.stringify(j,null,2)+'\n');
}
run('npm',['run','build']);
run('npx',['electron-builder','--win','dir','--x64','--config.directories.output=release-0.5','--publish','never']);
const payload=path.join(source,'release-0.5/win-unpacked');
const PE=require('pe-library'),RE=require('resedit');
async function identity(input,output,name,iconName){
 const exe=PE.NtExecutable.from(await fs.readFile(input),{ignoreCert:true}),res=PE.NtExecutableResource.from(exe);
 const versions=RE.Resource.VersionInfo.fromEntries(res.entries);
 if(!versions.length)versions.push(RE.Resource.VersionInfo.createEmpty());
 for(const vi of versions){
  vi.setFileVersion(0,5,2,0,1033);vi.setProductVersion(0,5,2,0,1033);
  vi.setStringValues({lang:1033,codepage:1200},{FileDescription:name,ProductName:name,InternalName:name,OriginalFilename:path.basename(output),CompanyName:'Hasbreo'});vi.outputToResourceEntries(res.entries);
 }
 const icon=RE.Data.IconFile.from(await fs.readFile(path.join(source,'assets',iconName+'.ico')));
 const groups=RE.Resource.IconGroupEntry.fromEntries(res.entries);
 if(!groups.length)throw Error('Missing application icon resource: '+input);
 for(const group of groups)RE.Resource.IconGroupEntry.replaceIconsForResource(res.entries,group.id,group.lang,icon.icons.map(i=>i.data));
 res.outputResource(exe);await fs.writeFile(output,Buffer.from(exe.generate()));
}
await identity(path.join(payload,'HasOffice.exe'),path.join(payload,'HasOffice.exe'),'HasOffice','hasoffice');
for(const name of ['HasWord','HasCell','HasSlides','HasMail','HasPDF','HasOfficeUpdater'])
 await identity(path.join(payload,'HasOffice.exe'),path.join(payload,name+'.exe'),name,name==='HasOfficeUpdater'?'officeflow':name.toLowerCase());
await fs.cp(native,path.join(payload,'collabora'),{recursive:true});
await fs.access(path.join(payload,'collabora/LICENSE.html'));
for(const name of ['HasWord','HasCell','HasSlides']){
 const p=path.join(payload,'collabora/program',name+'.exe');await identity(p,p,name,name.toLowerCase());
}
await fs.rm(path.join(payload,'collabora/program/HasOffice.exe'),{force:true});
for(const [old,name] of Object.entries({WordFlow:'HasWord',CellFlow:'HasCell',SlideFlow:'HasSlides'}))await fs.copyFile(path.join(payload,'collabora/program',name+'.exe'),path.join(payload,'collabora/program',old+'.exe'));

for(const [old,current] of Object.entries({WordFlow:'HasWord',CellFlow:'HasCell',SlideFlow:'HasSlides',MailFlow:'HasMail',PDFFlow:'HasPDF',OfficeFlowUpdater:'HasOfficeUpdater',OfficeFlow:'HasOffice'}))
 await fs.copyFile(path.join(payload,current+'.exe'),path.join(payload,old+'.exe'));

// Use HasOffice's product identity rather than the vendor's commercial theme script.
for(const filename of ['branding.js','branding-app.js'])
 await fs.copyFile(path.join(integration,'native/branding.js'),path.join(payload,'collabora/cool',filename));
// Keep the final theme in sync without rebuilding the C++ engine for CSS changes.
for(const filename of ['branding.css','branding-officeflow.svg'])
 await fs.copyFile(path.join(integration,'../collabora/branding',filename),path.join(payload,'collabora/cool',filename));
// These commercial vendor agreement templates do not describe our source-built distribution.
// Keep LICENSE.html, NOTICE and all component copyright/licence notices.
for(const filename of ['EULA.odt','EULA_en-US.rtf'])
 await fs.rm(path.join(payload,'collabora',filename),{force:true});

run('pwsh.exe',['-NoProfile','-NonInteractive','-File',path.join(integration,'build-print-helper.ps1'),'-Destination',path.join(payload,'collabora')]);
await fs.writeFile(path.join(payload,'collabora/OFFICEFLOW-SOURCE.txt'),'HasOffice document editors use Collabora Online / LibreOffice technology.\nCorresponding pinned source and modifications: https://github.com/hasbreo/OfficeFlow\nComponent licences and attribution are retained in this directory.\n');
// Store Electron once in NSIS and reconstruct its six process identities.
const patches=path.join(source,'scripts/make-installer-patches.mjs');let text=await fs.readFile(patches,'utf8');
text=text.replace("OfficeFlow.exe", "HasOffice.exe").replaceAll("OfficeFlow.exe", "HasOffice.exe");text=text.replace("['WordFlow','CellFlow','SlideFlow','MailFlow','PDFFlow']", "['HasWord','HasCell','HasSlides','HasMail','HasPDF','HasOfficeUpdater']");await fs.writeFile(patches,text);
await fs.copyFile(path.join(integration,'installer.nsi'),path.join(source,'scripts/installer.nsi'));
let cleanup='';for(const [name,ext] of [['HasWord','docx'],['HasCell','xlsx'],['HasSlides','pptx'],['HasMail',''],['HasPDF','pdf']]){
 cleanup+=`Delete "$SMPROGRAMS\\HasOffice\\${name}.lnk"\n`;
 if(ext)cleanup+=`DeleteRegKey HKCU "Software\\Classes\\HasOffice.${ext}"\nDeleteRegValue HKCU "Software\\Classes\\.${ext}\\OpenWithProgids" "HasOffice.${ext}"\n`;
}
for(const ext of ['docx','xlsx','pptx','pdf'])cleanup+=`DeleteRegKey HKCU "Software\\Classes\\OfficeFlow.${ext}"\nDeleteRegValue HKCU "Software\\Classes\\.${ext}\\OpenWithProgids" "OfficeFlow.${ext}"\n`;
await fs.writeFile('scripts/uninstall-shortcuts.nsh',cleanup);
const webview=path.join(source,'build-deps/MicrosoftEdgeWebview2Setup.exe');
run('pwsh.exe',['-NoProfile','-NonInteractive','-File',path.join(integration,'fetch-webview-runtime.ps1'),'-Destination',webview]);
const installerScript=path.join(source,'scripts/native-installer.mjs');
let installerCode=await fs.readFile(installerScript,'utf8');
installerCode=installerCode.replace("'scripts/installer.nsi'","'-DWEBVIEW_SETUP='+process.env.OFFICEFLOW_WEBVIEW_SETUP,'scripts/installer.nsi'");
await fs.writeFile(installerScript,installerCode);process.env.OFFICEFLOW_WEBVIEW_SETUP=webview;
const compiler=await require('app-builder-lib/out/toolsets/windows').getMakeNsisPath('0.0.0');Object.assign(process.env,compiler.env);
process.env.MAKENSIS=compiler.path;process.env.OFFICEFLOW_PAYLOAD=payload;process.env.OFFICEFLOW_INSTALLER=path.join(source,'release-0.5/HasOffice-Setup-'+version+'.exe');
await import(pathToFileURL(path.join(source,'scripts/native-installer.mjs')));
