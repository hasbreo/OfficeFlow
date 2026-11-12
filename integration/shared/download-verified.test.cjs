const{test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs/promises'),os=require('node:os'),path=require('node:path'),crypto=require('node:crypto');
const{downloadVerified}=require('./download-verified.cjs');
test('streamed update verifies exact bytes; failure retains the last verified file',async()=>{
 const dir=await fs.mkdtemp(path.join(os.tmpdir(),'of-download-')),target=path.join(dir,'Setup.exe');
 try{
  const data=Buffer.from('verified installer fixture'),release={size:data.length,sha256:crypto.createHash('sha256').update(data).digest('hex')};
  await downloadVerified(new Response(data),release,target);assert.deepEqual(await fs.readFile(target),data);
  for(const bad of[Buffer.from('short'),Buffer.alloc(data.length),Buffer.alloc(data.length+1)]){
   await assert.rejects(downloadVerified(new Response(bad),release,target));assert.deepEqual(await fs.readFile(target),data);assert.deepEqual(await fs.readdir(dir),['Setup.exe']);
  }
 }finally{await fs.rm(dir,{recursive:true,force:true});}
});
