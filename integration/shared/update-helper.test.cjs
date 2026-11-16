const {test}=require('node:test'),assert=require('node:assert/strict');
const {runningApps,waitForClosed}=require('./update-helper.cjs');
test('native update install is blocked while any suite app is running',()=>{
 const names=runningApps((exe,args)=>{
  assert.equal(exe,'tasklist.exe');assert.deepEqual(args,['/FO','CSV','/NH']);
  return {status:0,stdout:'"HasWord.exe","42"\r\n"HasOfficeUpdater.exe","43"\r\n"HasCell.exe","44"\r\n"HasWord.exe","45"'};
 });
 assert.deepEqual(names,['hasword.exe','hascell.exe']);
 assert.throws(()=>runningApps(()=>({status:1,stdout:''})),/Cannot verify/);
});
test('closing native programs is user-driven and cancelling never installs',async()=>{
 assert.equal(await waitForClosed({showMessageBox:async()=>({response:1})},()=>['wordflow.exe']),false);
 let reads=0;
 assert.equal(await waitForClosed({showMessageBox:async()=>({response:0})},()=>++reads===1?['wordflow.exe']:[]),true);
});
