// Main-process mail polling survives hidden/destroyed renderer windows.
class MailBackground {
 constructor({accounts,sync,busy,status=()=>{},interval=300000}){Object.assign(this,{accounts,sync,busy,status,interval});this.running=null;this.stopped=false;}
 run(){if(this.stopped)return Promise.resolve();if(this.running)return this.running;this.running=this.poll().finally(()=>{this.running=null;});return this.running;}
 async poll(){if(this.busy())return;let failed=false;try{for(const account of await this.accounts()){if(this.stopped)break;if(this.busy())break;try{this.status('Syncing '+account);await this.sync(account);}catch(error){failed=true;this.status('Sync needs attention: '+error.message);}}if(!failed)this.status('Running in background · checks every 5 minutes');}catch(error){this.status('Sync needs attention: '+error.message);}}
 start(){this.first=setTimeout(()=>this.run(),1500);this.timer=setInterval(()=>this.run(),this.interval);}
 stop(){this.stopped=true;clearTimeout(this.first);clearInterval(this.timer);return this.running||Promise.resolve();}
}
module.exports={MailBackground};
