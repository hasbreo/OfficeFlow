// Shared updater for the native document apps. Never opens or sends mail.
const path=require('node:path');
const fs=require('node:fs/promises');
const {spawnSync}=require('node:child_process');
const documentProcesses=new Set(['wordflow.exe','cellflow.exe','slideflow.exe','mailflow.exe','pdfflow.exe']);
function runningApps(run=spawnSync){
 const r=run('tasklist.exe',['/FO','CSV','/NH'],{encoding:'utf8',windowsHide:true,timeout:10000});
 if(r.error||r.status!==0)throw Error('Cannot verify that OfficeFlow programs are closed. Close them before running the installer.');
 return [...new Set(String(r.stdout).split(/\r?\n/).map(line=>/^"([^"]+)"/.exec(line)?.[1]?.toLowerCase()).filter(name=>documentProcesses.has(name)))];
}
async function waitForClosed(dialog,run=runningApps){
 while(true){
  const open=run();
  if(!open.length)return true;
  const {response}=await dialog.showMessageBox({type:'info',message:'Close the open OfficeFlow programs first.',detail:open.map(n=>n.replace(/\.exe$/i,'')).join(', ')+'\nSave your work and close these programs, then choose Try again.',buttons:['Try again','Later'],defaultId:1,cancelId:1});
  if(response!==0)return false;
 }
}
async function run(){
 const {app,dialog,shell}=require('electron');
 const {Updater}=require('./updates.cjs');
 const {FileStore}=require('./storage.cjs');
 const startup=process.argv.includes('--startup');
 app.setName('OfficeFlow Updates');
 app.setPath('userData',path.join(app.getPath('appData'),'officeflow','processes','update-helper'));
 if(!app.requestSingleInstanceLock()){app.quit();return;}
 await app.whenReady();
 try{
  const root=process.env.OFFICEFLOW_DATA_DIR||path.join(app.getPath('appData'),'officeflow');
  const store=new FileStore(root),settings=await store.settings();
  if(startup&&settings.autoUpdates===false)return;
  const config=JSON.parse(await fs.readFile(path.join(__dirname,'../release-config.json'),'utf8'));
  const prompts={showMessageBox:async(_owner,options)=>{
   if(options.message==='Close OfficeFlow and install the update?' && !await waitForClosed(dialog))return {response:1};
   return dialog.showMessageBox(options);
  }};
  const updater=new Updater(app,prompts,shell,config,()=>runningApps().length===0);
  await updater.check(null,!startup);
 }catch(error){
  if(!startup)await dialog.showMessageBox({type:'error',message:'Unable to check for updates',detail:error.message});
 }finally{app.quit();}
}
module.exports={run,runningApps,waitForClosed};
