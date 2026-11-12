// Keep the existing MailFlow/PDFFlow profile; document shortcuts launch native hosts.
const path=require('node:path');
const {app,dialog}=require('electron');
const {spawn}=require('node:child_process');
const updater=process.argv.includes('--update-helper')||path.basename(process.execPath).toLowerCase()==='officeflowupdater.exe';
if(updater)require('./update-helper.cjs').run();
else{
 const launch=require('./launch.cjs').resolveLaunch({argv:process.argv,execPath:process.execPath,envKind:process.env.OFFICEFLOW_KIND});
 const name={word:'WordFlow',cell:'CellFlow',slide:'SlideFlow'}[launch.kind];
 if(name)app.whenReady().then(()=>{
  const target=path.join(path.dirname(process.execPath),'collabora','program',name+'.exe');
  const child=spawn(target,launch.file?[launch.file]:[],{detached:true,stdio:'ignore',cwd:path.dirname(target)});
  child.once('spawn',()=>{child.unref();app.quit();});
  child.once('error',async error=>{await dialog.showMessageBox({type:'error',message:name+' could not start.',detail:'Reinstall OfficeFlow to restore the editor.\n'+error.message});app.quit();});
 });
 else require('./legacy-main.cjs');
}
