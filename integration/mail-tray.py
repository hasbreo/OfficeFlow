"""Guarded additions to the pinned shared MailFlow source."""
from pathlib import Path
import shutil

def apply(root):
 p=root/'desktop/legacy-main.cjs';s=p.read_text()
 if '// MailFlow tray lifecycle' in s:return
 def change(old,new):
  nonlocal s
  assert old in s,old[:100]
  s=s.replace(old,new,1)
 change("net,Notification}=require('electron')","net,Notification,Tray}=require('electron')")
 change("if(process.platform==='win32'){",'''// MailFlow tray lifecycle
let mailTray,background,quitting=false,quitPending=false,syncWork=null;
function mailWindow(){return BrowserWindow.getAllWindows().find(w=>windows.get(w.id)?.kind==='mail'&&!w.isDestroyed());}
function showMail(){const w=mailWindow()||createWindow('mail');if(w.isMinimized())w.restore();w.show();w.focus();return w;}
function broadcast(action,payload){for(const w of BrowserWindow.getAllWindows())if(!w.isDestroyed())send(w,action,payload);}
function syncMail(account){if(syncWork)return syncWork;syncWork=performSync(account).finally(()=>{syncWork=null;broadcast('mailSyncDone');});return syncWork;}
async function performSync(account){const before=new Set((await mail.index()).messages.map(m=>m.id));const result=await mail.sync(account,p=>broadcast('syncProgress',p));const settings=await store.settings();if(settings.mailBackupDirectory)try{result.backup=await mail.backup(settings.mailBackupDirectory);}catch(e){result.backupError=e.message;}if(settings.mailNotifications!==false){const incoming=(await mail.index()).messages.filter(m=>!before.has(m.id)&&m.account===account&&m.labels.includes('INBOX')&&m.labels.includes('UNREAD'));if(incoming.length&&Notification.isSupported()){const notice=new Notification({title:'MailFlow',body:`${incoming.length} new messages downloaded`,silent:true});notice.on('click',showMail);notice.show();}}return result;}
function loginSetting(enabled){if(process.platform==='win32')app.setLoginItemSettings({openAtLogin:!!enabled,path:path.join(path.dirname(process.execPath),'MailFlow.exe'),args:['--background']});}
if(process.platform==='win32'){''')
 change("createWindow(launch.kind,launch.file);});}","if(processKind==='mail'){if(!argv.includes('--background'))showMail();}else createWindow(launch.kind,launch.file);});}")
 change("backgroundColor:'#101a20',title:","show:!(kind==='mail'&&process.argv.includes('--background')),backgroundColor:'#101a20',title:")
 change("if(closing)return;if(dirty.has(win.id))", "if(closing)return;if(kind==='mail'&&mailTray&&!quitting){e.preventDefault();win.hide();return;}if(dirty.has(win.id))")
 change("'mailBackupDirectory','mailNotifications'","'mailBackupDirectory','mailNotifications','mailStartWithWindows'")
 change("return store.setSettings(safe);", "if('mailStartWithWindows' in safe)loginSetting(safe.mailStartWithWindows);return store.setSettings(safe);")
 a=s.index("handle('sync',async(win,account)=>");b=s.index("handle('cancelSync'",a)
 s=s[:a]+"handle('sync',(win,account)=>{if(syncWork)return syncWork.then(()=>({count:0,cancelled:false}));return syncMail(account);});"+s[b:]
 change("createWindow(initialLaunch.kind,initialLaunch.file);",'''if(processKind==='mail'){
  try{mailTray=new Tray(path.join(__dirname,'../assets/mailflow.ico'));mailTray.setToolTip('MailFlow · background mail archive');mailTray.on('click',showMail);mailTray.setContextMenu(Menu.buildFromTemplate([{label:'Open MailFlow',click:showMail},{label:'Sync now',click:()=>background.run()},{type:'separator'},{label:'Quit MailFlow',click:()=>app.quit()}]));}catch(e){console.error('Tray:',e.message);}
  background=new (require('./mail-background.cjs').MailBackground)({accounts:()=>auth.accounts(),sync:syncMail,busy:()=>mail.busy||tasks.running,status:text=>mailTray?.setToolTip(('MailFlow · '+text).slice(0,127))});background.start();
  if(mailSettings.mailStartWithWindows)loginSetting(true);
 }
 if(!mailTray||!process.argv.includes('--background'))createWindow(initialLaunch.kind,initialLaunch.file);''')
 change("app.on('window-all-closed',()=>app.quit());",'''app.on('before-quit',e=>{if(processKind!=='mail'||quitting)return;e.preventDefault();if(quitPending)return;quitPending=true;mail.cancel=true;Promise.all([background?.stop(),syncWork]).catch(()=>{}).finally(()=>{quitting=true;app.quit();});});
app.on('will-quit',()=>mailTray?.destroy());
app.on('window-all-closed',()=>{if(processKind!=='mail'||!mailTray||quitting)app.quit();});''')
 p.write_text(s)
 shutil.copyfile(Path(__file__).parent/'shared/mail-background.cjs',root/'desktop/mail-background.cjs')
 p=root/'src/mail.jsx';s=p.read_text();a=s.index(' useEffect(()=>{if(!desktop||!accounts.includes(account))return;');b=s.index('\n',a);s=s[:a]+s[b:];s=s.replace("if(action==='mailTasksChanged')","if(action==='mailTasksChanged'||action==='mailSyncDone')");p.write_text(s)
 p=root/'src/main.jsx';s=p.read_text();old='<h3>Mail archive protection</h3>';assert old in s;s=s.replace(old,'''<h3>Background mail archive</h3><p>Closing MailFlow keeps it in the system tray, checking all connected accounts every five minutes. Right-click its tray icon and choose Quit MailFlow to stop it.</p><label className="check"><input type="checkbox" checked={!!form.mailStartWithWindows} onChange={e=>setForm({...form,mailStartWithWindows:e.target.checked})}/>Start MailFlow quietly with Windows</label><hr/><h3>Mail archive protection</h3>''');p.write_text(s)
