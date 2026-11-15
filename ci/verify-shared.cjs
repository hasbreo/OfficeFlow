const{_electron:electron}=require('playwright'),fs=require('node:fs/promises'),path=require('node:path'),assert=require('node:assert/strict');
const root=process.argv[2];
(async()=>{
 await fs.mkdir('probe-results',{recursive:true});
 for(const[name,kind]of[['MailFlow','mail'],['PDFFlow','pdf']]){
  const app=await electron.launch({executablePath:path.join(root,name+'.exe'),args:[],env:{...process.env,OFFICEFLOW_DATA_DIR:path.join(process.env.APPDATA,'officeflow')}});
  try{
   const page=await app.firstWindow();await page.waitForLoadState('domcontentloaded');
   assert.equal(await app.evaluate(({app})=>app.getName()),name);
   assert.equal(new URL(page.url()).searchParams.get('app'),kind);
   if(kind==='mail')await page.getByRole('button',{name:'New message',exact:true}).waitFor();
   else await page.getByText('PDFFlow',{exact:true}).first().waitFor();
   if(kind==='mail'){
    await page.evaluate(()=>window.officeflow.settings({mailStartWithWindows:true}));
    assert.equal(await app.evaluate(({app})=>app.getLoginItemSettings({path:require('node:path').join(require('node:path').dirname(process.execPath),'MailFlow.exe'),args:['--background']}).openAtLogin),true);
    await page.evaluate(()=>window.officeflow.settings({mailStartWithWindows:false}));
    assert.equal(await app.evaluate(({app})=>app.getLoginItemSettings({path:require('node:path').join(require('node:path').dirname(process.execPath),'MailFlow.exe'),args:['--background']}).openAtLogin),false);
    await app.evaluate(({BrowserWindow})=>BrowserWindow.getAllWindows()[0].close());
    assert.equal(await app.evaluate(({BrowserWindow})=>BrowserWindow.getAllWindows()[0].isVisible()),false);
    await app.evaluate(({app})=>app.emit('second-instance',{},[process.execPath]));
    assert.equal(await app.evaluate(({BrowserWindow})=>BrowserWindow.getAllWindows()[0].isVisible()),true);
    assert.equal(await app.evaluate(({BrowserWindow})=>BrowserWindow.getAllWindows().length),1);
    console.log('MailFlow tray close, Start-menu reopen, single window and Windows startup toggle PASS');
   }
   await page.screenshot({path:'probe-results/'+name+'.png'});
   console.log(name+' installed application starts independently PASS');
  }finally{await app.close();}
 }
 const quiet=await electron.launch({executablePath:path.join(root,'MailFlow.exe'),args:['--background'],env:{...process.env,OFFICEFLOW_DATA_DIR:path.join(process.env.APPDATA,'officeflow')}});
 try{
  await quiet.evaluate(async({app,ipcMain})=>{await app.whenReady();for(let i=0;i<100&&!ipcMain._invokeHandlers.has('mailIndex');i++)await new Promise(r=>setTimeout(r,100));if(!ipcMain._invokeHandlers.has('mailIndex'))throw Error('Mail startup did not finish');});
  assert.equal(await quiet.evaluate(({BrowserWindow})=>BrowserWindow.getAllWindows().filter(w=>w.isVisible()).length),0);
  await quiet.evaluate(({app})=>app.emit('second-instance',{},[process.execPath]));
  const page=await quiet.firstWindow();await page.getByRole('button',{name:'New message',exact:true}).waitFor();
  assert.equal(await quiet.evaluate(({BrowserWindow})=>BrowserWindow.getAllWindows()[0].isVisible()),true);
  console.log('MailFlow quiet startup and reopen PASS');
 }finally{await quiet.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
