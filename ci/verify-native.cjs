// Run against OfficeFlow's actual source-built native hosts and OOXML templates.
const {chromium}=require('playwright'),{spawn,spawnSync}=require('node:child_process');
const fs=require('node:fs/promises'),path=require('node:path'),assert=require('node:assert/strict');
const {unzipSync,strFromU8}=require('fflate');
const root=path.resolve(process.argv[2]),out=path.resolve('probe-results');
const upstream=process.argv.includes('--upstream-fixture'),rich=process.argv.includes('--rich');
const fixtures=[['WordFlow','TextDocument.docx','text','word/document.xml'],['CellFlow','Spreadsheet.xlsx','spreadsheet','xl/worksheets/sheet1.xml'],['SlideFlow','Presentation.pptx','presentation','ppt/presentation.xml']];
const pause=ms=>new Promise(r=>setTimeout(r,ms));
async function readPart(file,part){return strFromU8(unzipSync(await fs.readFile(file))[part]);}
async function connect(child,port){
 const until=Date.now()+120000;let browser;
 while(Date.now()<until){
  if(child.exitCode!==null)throw Error('Native process exited '+child.exitCode);
  try{browser=await chromium.connectOverCDP('http://127.0.0.1:'+port);break;}catch{await pause(700);}
 }
 assert(browser,'Native debugging endpoint unavailable');let page;
 while(Date.now()<until){page=browser.contexts().flatMap(c=>c.pages()).find(p=>p.url().includes('cool.html'));if(page)return{browser,page};await pause(400);}
 throw Error('Native document view was not created');
}
async function close(child){
 const r=spawnSync('powershell.exe',['-NoProfile','-NonInteractive','-File',path.join(__dirname,'close-native-window.ps1'),'-ProcessId',String(child.pid)],{encoding:'utf8'});
 assert.equal(r.status,0,r.stdout+r.stderr);
 const until=Date.now()+45000;while(child.exitCode===null&&Date.now()<until)await pause(300);
 assert.equal(child.exitCode,0,'Saved editor did not close normally');
}
(async()=>{
 await fs.mkdir(out,{recursive:true});
 for(let i=0;i<fixtures.length;i++){
  const[name,template,type,part]=fixtures[i],exe=path.join(root,'program',upstream?'Collabora Office Preview.exe':name+'.exe'),doc=path.join(out,template),profile=path.join(out,name+'-profile'),port=9240+i;
  const richName=['RichDocument.docx','RichWorkbook.xlsx','RichPresentation.pptx'][i];
  const source=rich?path.join(__dirname,'fixtures',richName):upstream?path.join(__dirname,'../collabora/templates',template):path.join(root,'templates',template);
  await fs.copyFile(source,doc);await fs.mkdir(profile,{recursive:true});
  const launch=()=>spawn(exe,[doc],{cwd:path.dirname(exe),env:{...process.env,CODA_TEST_DATA_DIR:profile,CODA_TEST_REMOTE_DEBUGGING_PORT:String(port),CODA_LOGLEVEL:'warning'},stdio:'ignore'});
  let child=launch(),browser,page;
  try{
   ({browser,page}=await connect(child,port));
   if(!upstream)assert.equal(new URL(page.url()).searchParams.get('officeflowApp'),name);
   await page.waitForFunction(()=>globalThis.app?.map?._docLayer?._docType,null,{timeout:90000});
   assert.equal(await page.evaluate(()=>app.map._docLayer._docType),type);
   if(process.argv.includes('--expect-editable'))assert.equal(await page.evaluate(()=>globalThis.brandProductName),name,'Installed UI product identity differs');
   if(!process.argv.includes('--expect-editable')&&await page.getByText('Viewing',{exact:true}).isVisible()){
    await page.getByText('Viewing',{exact:true}).click();await page.getByText('Editing Mode',{exact:true}).click();
   }
   await page.waitForFunction(()=>app.map.isEditMode(),null,{timeout:30000});
   const before=await readPart(doc,part);
   if(name==='WordFlow'){await page.evaluate(()=>app.map.focus());await page.keyboard.type('OfficeFlow saved document test');}
   else if(name==='CellFlow'){
    for(const[cell,value]of[['A1','8'],['B1','=A1*2']]){
     await page.evaluate(cell=>app.map.sendUnoCommand('.uno:GoToCell',{ToPoint:{type:'string',value:cell}}),cell);
     await page.evaluate(()=>app.map.focus());await page.keyboard.type(value);await page.keyboard.press('Enter');
    }
   }else await page.evaluate(()=>app.map.insertPage());
   await page.evaluate(()=>app.map.save(false,false));let good=false;const until=Date.now()+45000;
   while(Date.now()<until){
    try{const xml=await readPart(doc,part);
     good=name==='WordFlow'?xml.includes('OfficeFlow saved document test'):name==='CellFlow'?/<f[^>]*>A1\*2<\/f>/.test(xml)&&/<v>16<\/v>/.test(xml):(xml.match(/<p:sldId\s/g)||[]).length>(before.match(/<p:sldId\s/g)||[]).length;
     if(good)break;
    }catch{}await pause(300);
   }
   assert(good,name+' content did not survive native OOXML save');
   if(rich){
    const archive=unzipSync(await fs.readFile(doc)),parts=Object.keys(archive),xml=await readPart(doc,part);
    if(name==='WordFlow'){
     assert(xml.includes('<w:tbl>'),'Document table was lost');assert(parts.some(p=>p.startsWith('word/media/')),'Document image was lost');
     assert(parts.filter(p=>/^word\/header\d+\.xml$/.test(p)).some(p=>strFromU8(archive[p]).includes('OfficeFlow fixture header')),'Header was lost');
    }else if(name==='CellFlow'){
     assert(/<v>17<\/v>/.test(xml)&&/<v>24<\/v>/.test(xml),'Cross-sheet formulas did not calculate');
     assert(parts.some(p=>/^xl\/charts\/chart\d+\.xml$/.test(p)),'Workbook chart was lost');
    }else assert(parts.some(p=>p.startsWith('ppt/media/')),'Slide image was lost');
   }
   const pdf=path.join(out,name+'-export.pdf');await fs.rm(pdf,{force:true});
   const picker=spawn('powershell.exe',['-NoProfile','-NonInteractive','-File',path.join(__dirname,'save-native-pdf.ps1'),'-ProcessId',String(child.pid),'-Destination',pdf],{stdio:'inherit'});
   await page.evaluate(()=>window.postMobileMessage('downloadas name=OfficeFlow.pdf id=export format=pdf options='));
   const pdfUntil=Date.now()+60000;let pdfBytes;
   while(Date.now()<pdfUntil){try{pdfBytes=await fs.readFile(pdf);if(pdfBytes.length>1000&&pdfBytes.subarray(0,5).toString()==='%PDF-')break;}catch{}await pause(300);}
   assert(pdfBytes&&pdfBytes.length>1000&&pdfBytes.subarray(0,5).toString()==='%PDF-',name+' native PDF export failed');
   if(picker.exitCode===null)await new Promise(resolve=>picker.once('exit',resolve));
   assert.equal(picker.exitCode,0,'Native PDF save dialog did not complete');
   await page.screenshot({path:path.join(out,name+'.png')});await fs.writeFile(path.join(out,name+'.txt'),await page.locator('body').innerText());
   await close(child);await browser.close();browser=null;
   // Reopen the bytes just written using the same real native application.
   child=launch();({browser,page}=await connect(child,port));
   await page.waitForFunction(()=>globalThis.app?.map?._docLayer?._docType,null,{timeout:90000});
   assert.equal(await page.evaluate(()=>app.map._docLayer._docType),type);await close(child);
   console.log(name+' native edit, OOXML save, PDF export, normal close and reopen PASS');
  }catch(error){
   if(page){await page.screenshot({path:path.join(out,name+'-failure.png')}).catch(()=>{});await fs.writeFile(path.join(out,name+'-failure.txt'),await page.locator('body').innerText()).catch(()=>{});}throw error;
  }finally{if(browser)await browser.close().catch(()=>{});if(child.exitCode===null)spawnSync('taskkill',['/PID',String(child.pid),'/T','/F'],{stdio:'ignore'});}
 }
})().catch(error=>{console.error(error);process.exitCode=1;});
