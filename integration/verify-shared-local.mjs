import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
const source=path.resolve(process.argv[2]),require=createRequire(path.join(source,'package.json'));
const { _electron:electron }=require('playwright'),{PDFDocument}=require('pdf-lib');
const runtime=path.join(source,'node_modules/electron/dist'),root=await fs.mkdtemp(path.join(os.tmpdir(),'officeflow-shared-'));
await fs.writeFile(path.join(root,'settings.json'),JSON.stringify({autoUpdates:false,theme:'dark',mailArchiveConfirmed:true}));
const sentinel=path.join(root,'retained-mail.eml'),body='Subject: Synthetic retained mail\n\nPreserve this.';await fs.writeFile(sentinel,body);
const pdf=await PDFDocument.create();pdf.addPage([595,842]).drawText('OfficeFlow startup PDF fixture',{x:50,y:750,size:18});const file=path.join(root,'fixture.pdf');await fs.writeFile(file,await pdf.save());
for(const[name,kind]of[['MailFlow','mail'],['PDFFlow','pdf']]){
 const executable=path.join(runtime,name);await fs.link(path.join(runtime,'electron'),executable).catch(e=>{if(e.code!=='EEXIST')throw e;});
 const env={...process.env,OFFICEFLOW_DATA_DIR:root};delete env.OFFICEFLOW_KIND;
 const app=await electron.launch({executablePath:executable,args:['--no-sandbox','--ozone-platform=headless','--disable-gpu',source,...(kind==='pdf'?[file]:[])],env});
 try{
  const page=await app.firstWindow();assert.equal(await app.evaluate(({app})=>app.getName()),name);assert.equal(new URL(page.url()).searchParams.get('app'),kind);
  if(kind==='mail')await page.getByRole('button',{name:'New message',exact:true}).waitFor();
  else await page.locator('.pdf-text-layer').getByText('OfficeFlow startup PDF fixture').waitFor({timeout:45000});
  console.log(name+' executable-only startup and renderer PASS');
 }finally{await app.evaluate(({app})=>app.exit(0)).catch(()=>{});}
}
assert.equal(await fs.readFile(sentinel,'utf8'),body);console.log('Shared profile sentinel retained PASS');
