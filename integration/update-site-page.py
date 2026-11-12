"""Update the OfficeFlow download page only after the candidate is verified."""
from pathlib import Path
import argparse,json,math

def update(site,plan):
    p=site/'public/officeflow/index.html'
    html=p.read_text()
    changes={
      'Choose the programs you want in your Start menu. Each opens its own workspace, with shared settings, recovery and updates.':'Choose the programs you want in your Start menu. Each opens independently, with one installer and a shared update service.',
      'Write with familiar formatting, images, tables and review tools. Save locally, keep previous versions and export searchable PDFs.':'Write with styles, page layouts, tables, pictures, comments and revision tools. The full local Collabora engine handles editing, printing and PDF export.',
      'Work with everyday formulas and cross-sheet references. Import CSV, refresh linked workbook ranges and print selected ranges across multiple pages.':'Work with cell and cross-sheet formulas, charts, sorting, filters and print layouts. Open Excel workbooks or start a new spreadsheet with the full native engine.',
      'Build and edit slides with text, pictures and shapes. Present your deck, save an editable copy or export it to PDF.':'Build slides with layouts, text, pictures and shapes. Use the full presentation editor to arrange your deck, present it, save PPTX files and export PDFs.',
      'Tabbed ribbons group the everyday commands together. Collapse the ribbon when you want more room, or open File for saving, printing, PDF export and version history. Mint highlights and soft dark surfaces carry through the suite, with a light appearance when you prefer it.':'WordFlow, CellFlow and SlideFlow now use Collabora’s complete native tabbed interface, with contextual tools and OfficeFlow mint accents. Open File for saving, printing and PDF export. The document engine runs locally, without a document server or subscription.',
      'Choose dark or light appearance and optional backup folders in Settings.':'Choose your appearance in each app. Set a separate mail backup folder in MailFlow to protect your downloaded archive.',
      'Help → Check for updates':'File → Check for updates',
      'Source code · AGPL ↗':'Source code ↗',
      'Automatic checks can be switched off in Settings. Local document editing works offline.':'Automatic checks can be switched off in MailFlow or PDFFlow Settings; this preference applies to the suite. Local document editing works offline.',
      ', or the update button at the top of the window.':' in WordFlow, CellFlow and SlideFlow, or the update button in MailFlow and PDFFlow.',
      'OfficeFlow verifies the signed release information and downloaded installer, then offers to close the suite and open Setup. Save open documents first.':'OfficeFlow verifies the signed release information and downloaded installer. Save your work and close the open apps before installing; the updater waits for you.',
      'Open and save DOCX, XLSX and PPTX files locally. Recovery copies run every 30 seconds while editing, and saves keep the previous on-disk version in History. Choose a second document backup folder in Settings.':'Open and save DOCX, XLSX and PPTX files locally with the full Collabora document engine. Your existing files remain in their chosen locations. MailFlow and PDFFlow keep their existing user profiles and downloaded archives when you update.',
      'PDF exports preserve the rendered appearance and add a searchable text layer. CellFlow can paginate a selected worksheet range.':'Use the native document apps to print and export PDFs. The printing helper includes its runtime, and Setup installs Microsoft WebView2 when needed; that dependency installation requires an internet connection.',
      'Workbook range links import refreshable values. Existing Excel external-reference formulas are not automatically refreshed.':'Excel macros and complex external workbook links may behave differently. Test important files on copies before relying on them.',
      'Desktop workflows were checked in Linux. Native Windows installation, physical printing and real Gmail sign-in still need testing on your machine.':'Windows checks cover native Office-file editing, saving and reopening, PDF exports, individual app shortcuts, upgrades and mail retention. Physical printers and your own complex documents still depend on your local setup.',
      'MailFlow gains a clearer layout, distinct unread messages, automatic first-sync recovery, HTTPS email images and message context menus. Right-click menus across the suite, plus click-picked cell references and ranges in CellFlow.':'WordFlow, CellFlow and SlideFlow move to the full local Collabora desktop engine. Independent native apps, complete tabbed tools, Office file editing, PDF exports and shared signed updates. MailFlow and PDFFlow retain their existing data.',
      'Version 0.4.3 is AGPL-3.0-or-later. The source archive includes build scripts, dependency licences and the corresponding MuPDF source.':'The shared application is AGPL-3.0-or-later. Native Collabora source retains its MPL-2.0 notices. The source archive includes the pinned native build recipe, modifications, dependency licences and corresponding MuPDF source.'
    }
    for old,new in changes.items():
        if html.count(old)!=1:raise ValueError('Download page changed: '+old[:70])
        html=html.replace(old,new)
    html=html.replace('0.4.3',plan['version'])
    html=html.replace('202 MB',str(math.ceil(plan['files']['installer']['size']/1000000))+' MB')
    p.write_text(html)
    print('Updated OfficeFlow download page for',plan['version'])
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('site',type=Path);parser.add_argument('plan',type=Path);args=parser.parse_args();update(args.site,json.loads(args.plan.read_text()))
