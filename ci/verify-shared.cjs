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
   await page.screenshot({path:'probe-results/'+name+'.png'});
   console.log(name+' installed application starts independently PASS');
  }finally{await app.close();}
 }
})().catch(error=>{console.error(error);process.exitCode=1;});
