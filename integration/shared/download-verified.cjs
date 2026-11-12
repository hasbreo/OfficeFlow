const fs=require('node:fs/promises'),crypto=require('node:crypto');
async function downloadVerified(response,release,target){
 const temporary=target+'.'+crypto.randomUUID()+'.tmp';let file;
 try{
  file=await fs.open(temporary,'wx',0o600);const hash=crypto.createHash('sha256');let size=0;
  for await(const value of response.body){
   const chunk=Buffer.from(value);size+=chunk.length;
   if(size>release.size)throw Error('Downloaded update exceeds its signed size');
   hash.update(chunk);let offset=0;
   while(offset<chunk.length){const {bytesWritten}=await file.write(chunk,offset,chunk.length-offset);if(!bytesWritten)throw Error('Unable to write update');offset+=bytesWritten;}
  }
  if(size!==release.size||hash.digest('hex')!==release.sha256)throw Error('Downloaded update failed integrity verification');
  await file.sync();await file.close();file=null;await fs.rename(temporary,target);
 }finally{if(file)await file.close();await fs.rm(temporary,{force:true});}
}
module.exports={downloadVerified};
