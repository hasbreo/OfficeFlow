"""Upload verified release parts. Publisher token is accepted through stdin only."""
import argparse,json,urllib.request,urllib.error,time
from pathlib import Path
class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self,*args,**kwargs):raise RuntimeError('Publisher unexpectedly redirected')
def upload(plan,directory,token):
    assert len(token)==64 and all(c in '0123456789abcdef' for c in token)
    opener=urllib.request.build_opener(NoRedirect)
    def request(kind,action,body=b'',part=None):
        url='https://hasbreo.com/api/officeflow/publish/'+kind+'/'+action
        if part is not None:url+='?part='+str(part)
        for attempt in range(3):
            try:
                req=urllib.request.Request(url,data=body,method='POST',headers={'Authorization':'Bearer '+token,'User-Agent':'OfficeFlow-Publisher/0.5','Content-Type':'application/octet-stream'})
                with opener.open(req,timeout=120) as response:result=json.load(response)
                if not result.get('ok'):raise RuntimeError('Publisher did not accept release part')
                return result
            except urllib.error.HTTPError as error:
                if error.code<500 or attempt==2:raise RuntimeError('Publisher returned HTTP '+str(error.code)) from None
            except (TimeoutError,urllib.error.URLError):
                if attempt==2:raise RuntimeError('Publisher connection failed') from None
            time.sleep(2*(attempt+1))
    for kind in ['installer','source']:
        item=plan['files'][kind];state=request(kind,'init')
        if state.get('complete'):print(kind,'already verified');continue
        with (directory/item['filename']).open('rb') as stream:
            for i,part in enumerate(item['parts'],1):
                body=stream.read(part['size']);assert len(body)==part['size']
                import hashlib
                assert hashlib.sha256(body).hexdigest()==part['sha256']
                request(kind,'part',body,i);print(kind,'part',i,'of',len(item['parts']),flush=True)
            assert not stream.read(1)
        result=request(kind,'complete');assert result.get('sha256')==item['sha256'];print(kind,'published and verified')
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('plan',type=Path);p.add_argument('directory',type=Path);a=p.parse_args()
    import sys
    upload(json.loads(a.plan.read_text()),a.directory,json.load(sys.stdin)['token'])
