// Exercise the official native desktop runtime on the Windows build machine.
// Test fixtures and profiles are isolated; no user documents or mail are used.
const {chromium}=require('playwright');
const {spawn}=require('node:child_process');
const fs=require('node:fs/promises'),path=require('node:path'),assert=require('node:assert/strict');
const {unzipSync,strFromU8}=require('fflate');
const root=path.resolve(process.argv[2]);
const executable=path.join(root,'program','Collabora Office Preview.exe');
const fixtures=[['writer','TextDocument.odt','text'],['calc','Spreadsheet.ods','spreadsheet'],['impress','Presentation.odp','presentation']];
(async()=>{
 await fs.mkdir('probe-results',{recursive:true});
 for(let i=0;i<fixtures.length;i++){
  const [kind,template,expected]=fixtures[i],profile=path.resolve('probe-results',kind+'-profile'),port=9222+i;
  const doc=path.resolve('probe-results',template);
  await fs.copyFile(path.join(root,'templates',template),doc);
  await fs.mkdir(profile,{recursive:true});
  const child=spawn(executable,[doc],{cwd:path.dirname(executable),env:{...process.env,CODA_TEST_DATA_DIR:profile,CODA_TEST_REMOTE_DEBUGGING_PORT:String(port),CODA_LOGLEVEL:'warning'},stdio:'ignore'});
  let browser,page;
  try{
   const until=Date.now()+90000;
   while(Date.now()<until){
    if(child.exitCode!==null)throw Error(kind+' native process exited '+child.exitCode);
    try{browser=await chromium.connectOverCDP('http://127.0.0.1:'+port);break;}catch{await new Promise(r=>setTimeout(r,1000));}
   }
   assert(browser,kind+' did not expose its test debugging endpoint');
   while(Date.now()<until){
    page=browser.contexts().flatMap(c=>c.pages()).find(p=>p.url().includes('cool.html'));
    if(page)break;
    await new Promise(r=>setTimeout(r,500));
   }
   assert(page,kind+' document view not created');
   await page.waitForFunction(()=>globalThis.app?.map?._docLayer?._docType,{timeout:90000});
   const type=await page.evaluate(()=>app.map._docLayer._docType);
   assert.equal(type,expected);
   await page.waitForFunction(()=>document.querySelector('#document-container canvas, .leaflet-tile-loaded, #map canvas'),{timeout:90000});
   // Existing files open in Viewing mode. Exercise the real mode chooser first.
   await page.getByText('Viewing',{exact:true}).click();
   await fs.writeFile('probe-results/'+kind+'-mode-menu.txt',await page.locator('body').innerText());
   await page.getByText('Editing Mode',{exact:true}).click();
   await page.waitForFunction(()=>app.map.isEditMode(),{timeout:30000});
   await page.waitForFunction(()=>document.querySelector('#notebookbar, .notebookbar'),{timeout:30000});
   const xmlBefore=strFromU8(unzipSync(await fs.readFile(doc))['content.xml']);
   if(kind==='writer'){
    await page.evaluate(()=>app.map.focus());
    await page.keyboard.type('OfficeFlow native editing check');
   }else if(kind==='calc'){
    for(const[cell,value]of[['A1','8'],['B1','=A1*2']]){
     await page.evaluate(cell=>app.map.sendUnoCommand('.uno:GoToCell',{ToPoint:{type:'string',value:cell}}),cell);
     await page.evaluate(()=>app.map.focus());
     await page.keyboard.type(value);await page.keyboard.press('Enter');
    }
   }else await page.evaluate(()=>app.map.insertPage());
   await page.evaluate(()=>app.map.save(false,false));
   const saveUntil=Date.now()+30000;
   let saved=false;
   while(Date.now()<saveUntil){
    try{
     const xml=strFromU8(unzipSync(await fs.readFile(doc))['content.xml']);
     if(kind==='writer')saved=xml.includes('OfficeFlow native editing check');
     else if(kind==='calc')saved=xml.includes('office:value="16"')&&xml.includes('table:formula=');
     else saved=(xml.match(/<draw:page\s/g)||[]).length>(xmlBefore.match(/<draw:page\s/g)||[]).length;
     if(saved)break;
    }catch{}
    await new Promise(r=>setTimeout(r,300));
   }
   assert(saved,kind+' edit did not survive native save');
   await page.screenshot({path:'probe-results/'+kind+'.png',fullPage:false});
   await fs.writeFile('probe-results/'+kind+'.txt',await page.locator('body').innerText());
   console.log(kind+' native editor rendered, entered Editing mode and saved real content PASS');
  }catch(error){
   if(page){
    await page.screenshot({path:'probe-results/'+kind+'-failure.png'}).catch(()=>{});
    await fs.writeFile('probe-results/'+kind+'-failure.txt',await page.locator('body').innerText()).catch(()=>{});
   }
   throw error;
  }finally{
   if(browser)await browser.close();
   spawn('taskkill',['/PID',String(child.pid),'/T','/F'],{stdio:'ignore'});
  }
 }
})().catch(e=>{console.error(e);process.exitCode=1;});
