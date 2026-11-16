import fs from 'node:fs/promises';import path from 'node:path';
const root=path.resolve(process.argv[2]);
for(const name of ['HasWord','HasCell','HasSlides','HasMail','HasPDF','HasOfficeUpdater'])await fs.copyFile(path.join(root,'HasOffice.exe'),path.join(root,name+'.exe'));
