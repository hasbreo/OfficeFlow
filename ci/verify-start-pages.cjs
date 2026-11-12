// Verify the way a user actually starts each installed document application.
const {chromium}=require('playwright'),{spawn,spawnSync}=require('node:child_process');
const fs=require('node:fs/promises'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(process.argv[2]),out=path.resolve('probe-results');
const pause=ms=>new Promise(r=>setTimeout(r,ms));
const apps=[['WordFlow','Blank Document','text','.docx'],['CellFlow','Blank Spreadsheet','spreadsheet','.xlsx'],['SlideFlow','Blank Presentation','presentation','.pptx']];
(async()=>{
 await fs.mkdir(out,{recursive:true});
 for(let i=0;i<apps.length;i++){
  const[name,label,type,extension]=apps[i],profile=path.join(out,name+'-start-profile'),docs=path.join(out,name+'-new-documents'),port=9270+i;
  await fs.mkdir(profile,{recursive:true});await fs.mkdir(docs,{recursive:true});
  const exe=path.join(root,'program',name+'.exe');
  const child=spawn(exe,[],{cwd:path.dirname(exe),env:{...process.env,CODA_TEST_DATA_DIR:profile,CODA_TEST_DOCUMENTS_DIR:docs,CODA_TEST_REMOTE_DEBUGGING_PORT:String(port),CODA_LOGLEVEL:'warning'},stdio:'ignore'});
  let browser,page;
  try{
   const until=Date.now()+120000;
   while(Date.now()<until){try{browser=await chromium.connectOverCDP('http://127.0.0.1:'+port);break;}catch{assert.equal(child.exitCode,null,name+' exited during startup');await pause(500);}}
   assert(browser,name+' startup endpoint missing');
   while(Date.now()<until){page=browser.contexts().flatMap(c=>c.pages()).find(p=>p.url().includes('starterMode=true'));if(page)break;await pause(250);}
   assert(page,name+' did not open its start page');assert.equal(new URL(page.url()).searchParams.get('officeflowApp'),name);
   await page.getByText(label,{exact:true}).waitFor({state:'visible',timeout:45000});
   for(const other of apps)if(other[0]!==name)assert.equal(await page.getByText(other[1],{exact:true}).isVisible(),false,name+' shows another application blank card');
   await page.screenshot({path:path.join(out,name+'-start.png')});
   await page.getByText(label,{exact:true}).click();page=null;
   while(Date.now()<until){
    for(const p of browser.contexts().flatMap(c=>c.pages())){
     if(await p.evaluate(()=>globalThis.app?.map?._docLayer?._docType).catch(()=>null)===type){page=p;break;}
    }
    if(page)break;await pause(250);
   }
   assert(page,name+' blank document did not open');
   assert.equal(new URL(page.url()).searchParams.get('officeflowApp'),name);
   await page.waitForFunction(()=>app.map.isEditMode(),null,{timeout:30000});
   assert((await fs.readdir(docs)).some(file=>file.endsWith(extension)),name+' created the wrong blank file format');
   await page.screenshot({path:path.join(out,name+'-new.png')});
   // An untouched new document must close through the normal window action.
   const r=spawnSync('powershell.exe',['-NoProfile','-NonInteractive','-File',path.join(__dirname,'close-native-window.ps1'),'-ProcessId',String(child.pid)],{encoding:'utf8'});
   assert.equal(r.status,0,r.stdout+r.stderr);
   const closeUntil=Date.now()+45000;while(child.exitCode===null&&Date.now()<closeUntil)await pause(250);
   assert.equal(child.exitCode,0,name+' blank document did not close normally');
   console.log(name+' own start page, correct blank format, ready-to-edit mode and normal blank close PASS');
  }catch(error){if(page)await page.screenshot({path:path.join(out,name+'-start-failure.png')}).catch(()=>{});throw error;}
  finally{if(browser)await browser.close().catch(()=>{});if(child.exitCode===null)spawnSync('taskkill',['/PID',String(child.pid),'/T','/F'],{stdio:'ignore'});}
 }
})().catch(error=>{console.error(error);process.exitCode=1;});
