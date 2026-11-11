const {test}=require('node:test'),assert=require('node:assert/strict');
const {runningApps,waitForClosed}=require('./update-helper.cjs');
test('native update install is blocked while any suite app is running',()=>{
 const names=runningApps((exe,args)=>{
  assert.equal(exe,'tasklist.exe');assert.deepEqual(args,['/FO','CSV','/NH']);
  return {status:0,stdout:'"WordFlow.exe","42"\r\n"OfficeFlowUpdater.exe","43"\r\n"CellFlow.exe","44"\r\n"WordFlow.exe","45"'};
 });
 assert.deepEqual(names,['wordflow.exe','cellflow.exe']);
 assert.throws(()=>runningApps(()=>({status:1,stdout:''})),/Cannot verify/);
});
test('closing native programs is user-driven and cancelling never installs',async()=>{
 assert.equal(await waitForClosed({showMessageBox:async()=>({response:1})},()=>['wordflow.exe']),false);
 let reads=0;
 assert.equal(await waitForClosed({showMessageBox:async()=>({response:0})},()=>++reads===1?['wordflow.exe']:[]),true);
});
