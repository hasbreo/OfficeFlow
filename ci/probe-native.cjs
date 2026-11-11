// Exercise the official native desktop runtime on the Windows build machine.
// Test fixtures and profiles are isolated; no user documents or mail are used.
const {chromium}=require('playwright');
const {spawn}=require('node:child_process');
const fs=require('node:fs/promises'),path=require('node:path'),assert=require('node:assert/strict');
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
  let browser;
  try{
   const until=Date.now()+90000;
   while(Date.now()<until){
    if(child.exitCode!==null)throw Error(kind+' native process exited '+child.exitCode);
    try{browser=await chromium.connectOverCDP('http://127.0.0.1:'+port);break;}catch{await new Promise(r=>setTimeout(r,1000));}
   }
   assert(browser,kind+' did not expose its test debugging endpoint');
   let page;
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
   await page.screenshot({path:'probe-results/'+kind+'.png',fullPage:false});
   await fs.writeFile('probe-results/'+kind+'.txt',await page.locator('body').innerText());
   console.log(kind+' native engine rendered '+expected+' PASS');
  }finally{
   if(browser)await browser.close();
   spawn('taskkill',['/PID',String(child.pid),'/T','/F'],{stdio:'ignore'});
  }
 }
})().catch(e=>{console.error(e);process.exitCode=1;});
