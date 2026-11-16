Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"
Name "HasOffice"
OutFile "${OUTPUT}"
InstallDir "$LOCALAPPDATA\Programs\HasOffice"
InstallDirRegKey HKCU "Software\Hasbreo\OfficeFlow" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma
SetCompressorDictSize 32
!define MUI_ICON "../assets/officeflow.ico"
!define MUI_UNICON "../assets/officeflow.ico"
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TEXT "Install HasWord, HasCell, HasSlides, HasMail and HasPDF.$\r$\n$\r$\nClose HasOffice programs before updating. Your documents and downloaded mail are kept."
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"
!include "app-identities.nsh"

Function .onInit
  nsExec::ExecToStack '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -Command "if (Get-Process -Name HasOffice,HasWord,HasCell,HasSlides,HasMail,HasPDF,OfficeFlow,WordFlow,CellFlow,SlideFlow,MailFlow,PDFFlow -ErrorAction SilentlyContinue) { exit 42 }"'
  Pop $0
  Pop $1
  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONINFORMATION "Close all HasOffice programs, then run Setup again. Save your work before closing." /SD IDOK
    Abort
  ${EndIf}
FunctionEnd

Function WebViewPresent
  ReadRegStr $0 HKCU "Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
  ${If} $0 == ""
  ${OrIf} $0 == "0.0.0.0"
    ReadRegStr $0 HKLM "SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
  ${EndIf}
FunctionEnd

Section "HasOffice apps and shared components (required)" Core
  SectionIn RO
  Call WebViewPresent
  ${If} $0 == ""
  ${OrIf} $0 == "0.0.0.0"
    InitPluginsDir
    File "/oname=$PLUGINSDIR\MicrosoftEdgeWebview2Setup.exe" "${WEBVIEW_SETUP}"
    DetailPrint "Installing Microsoft WebView2..."
    ExecWait '$\"$PLUGINSDIR\MicrosoftEdgeWebview2Setup.exe$\" /silent /install' $1
    Call WebViewPresent
    ${If} $0 == ""
    ${OrIf} $0 == "0.0.0.0"
      MessageBox MB_OK|MB_ICONINFORMATION "HasOffice needs Microsoft WebView2. Connect to the internet, then run Setup again." /SD IDOK
      Abort
    ${EndIf}
  ${EndIf}
  SetOutPath "$INSTDIR"
  File /r /x HasWord.exe /x HasCell.exe /x HasSlides.exe /x HasMail.exe /x HasPDF.exe /x HasOfficeUpdater.exe /x OfficeFlow.exe /x WordFlow.exe /x CellFlow.exe /x SlideFlow.exe /x MailFlow.exe /x PDFFlow.exe /x OfficeFlowUpdater.exe "${PAYLOAD}\*"
  SetOutPath "$INSTDIR\collabora\program"
  File "${PAYLOAD}\collabora\program\HasWord.exe"
  File "${PAYLOAD}\collabora\program\HasCell.exe"
  File "${PAYLOAD}\collabora\program\HasSlides.exe"
  SetOutPath "$INSTDIR"
  !insertmacro InstallHasWord
  !insertmacro InstallHasCell
  !insertmacro InstallHasSlides
  !insertmacro InstallHasMail
  !insertmacro InstallHasPDF
  !insertmacro InstallHasOfficeUpdater
  CopyFiles /SILENT "$INSTDIR\HasWord.exe" "$INSTDIR\WordFlow.exe"
  CopyFiles /SILENT "$INSTDIR\HasCell.exe" "$INSTDIR\CellFlow.exe"
  CopyFiles /SILENT "$INSTDIR\HasSlides.exe" "$INSTDIR\SlideFlow.exe"
  CopyFiles /SILENT "$INSTDIR\HasMail.exe" "$INSTDIR\MailFlow.exe"
  CopyFiles /SILENT "$INSTDIR\HasPDF.exe" "$INSTDIR\PDFFlow.exe"
  CopyFiles /SILENT "$INSTDIR\HasOfficeUpdater.exe" "$INSTDIR\OfficeFlowUpdater.exe"
  CopyFiles /SILENT "$INSTDIR\HasOffice.exe" "$INSTDIR\OfficeFlow.exe"
  CopyFiles /SILENT "$INSTDIR\collabora\program\HasWord.exe" "$INSTDIR\collabora\program\WordFlow.exe"
  CopyFiles /SILENT "$INSTDIR\collabora\program\HasCell.exe" "$INSTDIR\collabora\program\CellFlow.exe"
  CopyFiles /SILENT "$INSTDIR\collabora\program\HasSlides.exe" "$INSTDIR\collabora\program\SlideFlow.exe"
  RMDir /r "$SMPROGRAMS\OfficeFlow"
  Delete "$INSTDIR\Uninstall OfficeFlow.exe"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\OfficeFlow"
  WriteRegStr HKCU "Software\Hasbreo\OfficeFlow" "InstallDir" "$INSTDIR"
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "MailFlow"
  ${If} $0 != ""
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "HasMail" '$\"$INSTDIR\HasMail.exe$\" --background'
    DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "MailFlow"
  ${EndIf}
  WriteRegStr HKCU "Software\Classes\OfficeFlow.docx" "" "HasWord file"
  WriteRegStr HKCU "Software\Classes\OfficeFlow.docx\shell\open\command" "" '$\"$INSTDIR\collabora\program\HasWord.exe$\" $\"%1$\"'
  WriteRegStr HKCU "Software\Classes\OfficeFlow.xlsx" "" "HasCell file"
  WriteRegStr HKCU "Software\Classes\OfficeFlow.xlsx\shell\open\command" "" '$\"$INSTDIR\collabora\program\HasCell.exe$\" $\"%1$\"'
  WriteRegStr HKCU "Software\Classes\OfficeFlow.pptx" "" "HasSlides file"
  WriteRegStr HKCU "Software\Classes\OfficeFlow.pptx\shell\open\command" "" '$\"$INSTDIR\collabora\program\HasSlides.exe$\" $\"%1$\"'
  WriteRegStr HKCU "Software\Classes\OfficeFlow.pdf" "" "HasPDF file"
  WriteRegStr HKCU "Software\Classes\OfficeFlow.pdf\shell\open\command" "" '$\"$INSTDIR\HasPDF.exe$\" $\"%1$\"'
  WriteUninstaller "$INSTDIR\Uninstall HasOffice.exe"
  WriteRegStr HKCU "Software\Hasbreo\HasOffice" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\HasOffice" "DisplayName" "HasOffice"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\HasOffice" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\HasOffice" "Publisher" "Hasbreo"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\HasOffice" "UninstallString" '$\"$INSTDIR\Uninstall HasOffice.exe$\"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\HasOffice" "DisplayIcon" "$INSTDIR\resources\icons\officeflow.ico"
  CreateDirectory "$SMPROGRAMS\HasOffice"
SectionEnd
!macro Shortcut Name Kind Relative Extension
Section "${Name} shortcut" ${Kind}
  CreateShortCut "$SMPROGRAMS\HasOffice\${Name}.lnk" "$INSTDIR\${Relative}" "" "$INSTDIR\resources\icons\${Name}.ico" 0
  !if "${Extension}" != ""
    WriteRegStr HKCU "Software\Classes\HasOffice.${Extension}" "" "${Name} file"
    WriteRegStr HKCU "Software\Classes\HasOffice.${Extension}\shell\open\command" "" '$\"$INSTDIR\${Relative}$\" $\"%1$\"'
    WriteRegStr HKCU "Software\Classes\.${Extension}\OpenWithProgids" "HasOffice.${Extension}" ""
  !endif
SectionEnd
!macroend
!insertmacro Shortcut "HasWord" "word" "collabora\program\HasWord.exe" "docx"
!insertmacro Shortcut "HasCell" "cell" "collabora\program\HasCell.exe" "xlsx"
!insertmacro Shortcut "HasSlides" "slide" "collabora\program\HasSlides.exe" "pptx"
!insertmacro Shortcut "HasMail" "mail" "HasMail.exe" ""
!insertmacro Shortcut "HasPDF" "pdf" "HasPDF.exe" "pdf"
Section "Uninstall"
  DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "HasMail"
  DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "MailFlow"
  !include "uninstall-files.nsh"
  Delete "$INSTDIR\Uninstall HasOffice.exe"
  RMDir "$INSTDIR"
  !include "uninstall-shortcuts.nsh"
  RMDir "$SMPROGRAMS\HasOffice"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\HasOffice"
  DeleteRegKey HKCU "Software\Hasbreo\HasOffice"
  DeleteRegKey HKCU "Software\Hasbreo\OfficeFlow"
SectionEnd
