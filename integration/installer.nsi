Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"
Name "OfficeFlow"
OutFile "${OUTPUT}"
InstallDir "$LOCALAPPDATA\Programs\OfficeFlow"
InstallDirRegKey HKCU "Software\Hasbreo\OfficeFlow" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma
SetCompressorDictSize 32
!define MUI_ICON "../assets/officeflow.ico"
!define MUI_UNICON "../assets/officeflow.ico"
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TEXT "Install WordFlow, CellFlow, SlideFlow, MailFlow and PDFFlow.$\r$\n$\r$\nClose OfficeFlow programs before updating. Your documents and downloaded mail are kept."
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
  nsExec::ExecToStack '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -Command "if (Get-Process -Name WordFlow,CellFlow,SlideFlow,MailFlow,PDFFlow -ErrorAction SilentlyContinue) { exit 42 }"'
  Pop $0
  Pop $1
  ${If} $0 != 0
    MessageBox MB_OK|MB_ICONINFORMATION "Close all OfficeFlow programs, then run Setup again. Save your work before closing."
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

Section "OfficeFlow apps and shared components (required)" Core
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
      MessageBox MB_OK|MB_ICONINFORMATION "OfficeFlow needs Microsoft WebView2. Connect to the internet, then run Setup again."
      Abort
    ${EndIf}
  ${EndIf}
  SetOutPath "$INSTDIR"
  File /r /x WordFlow.exe /x CellFlow.exe /x SlideFlow.exe /x MailFlow.exe /x PDFFlow.exe /x OfficeFlowUpdater.exe "${PAYLOAD}\*"
  SetOutPath "$INSTDIR\collabora\program"
  File "${PAYLOAD}\collabora\program\WordFlow.exe"
  File "${PAYLOAD}\collabora\program\CellFlow.exe"
  File "${PAYLOAD}\collabora\program\SlideFlow.exe"
  SetOutPath "$INSTDIR"
  !insertmacro InstallWordFlow
  !insertmacro InstallCellFlow
  !insertmacro InstallSlideFlow
  !insertmacro InstallMailFlow
  !insertmacro InstallPDFFlow
  !insertmacro InstallOfficeFlowUpdater
  WriteUninstaller "$INSTDIR\Uninstall OfficeFlow.exe"
  WriteRegStr HKCU "Software\Hasbreo\OfficeFlow" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\OfficeFlow" "DisplayName" "OfficeFlow"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\OfficeFlow" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\OfficeFlow" "Publisher" "Hasbreo"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\OfficeFlow" "UninstallString" '$\"$INSTDIR\Uninstall OfficeFlow.exe$\"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\OfficeFlow" "DisplayIcon" "$INSTDIR\resources\icons\officeflow.ico"
  CreateDirectory "$SMPROGRAMS\OfficeFlow"
SectionEnd
!macro Shortcut Name Kind Relative Extension
Section "${Name} shortcut" ${Kind}
  CreateShortCut "$SMPROGRAMS\OfficeFlow\${Name}.lnk" "$INSTDIR\${Relative}" "" "$INSTDIR\resources\icons\${Kind}flow.ico" 0
  !if "${Extension}" != ""
    WriteRegStr HKCU "Software\Classes\OfficeFlow.${Extension}" "" "${Name} file"
    WriteRegStr HKCU "Software\Classes\OfficeFlow.${Extension}\shell\open\command" "" '$\"$INSTDIR\${Relative}$\" $\"%1$\"'
    WriteRegStr HKCU "Software\Classes\.${Extension}\OpenWithProgids" "OfficeFlow.${Extension}" ""
  !endif
SectionEnd
!macroend
!insertmacro Shortcut "WordFlow" "word" "collabora\program\WordFlow.exe" "docx"
!insertmacro Shortcut "CellFlow" "cell" "collabora\program\CellFlow.exe" "xlsx"
!insertmacro Shortcut "SlideFlow" "slide" "collabora\program\SlideFlow.exe" "pptx"
!insertmacro Shortcut "MailFlow" "mail" "MailFlow.exe" ""
!insertmacro Shortcut "PDFFlow" "pdf" "PDFFlow.exe" "pdf"
Section "Uninstall"
  !include "uninstall-files.nsh"
  Delete "$INSTDIR\Uninstall OfficeFlow.exe"
  RMDir "$INSTDIR"
  !include "uninstall-shortcuts.nsh"
  RMDir "$SMPROGRAMS\OfficeFlow"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\OfficeFlow"
  DeleteRegKey HKCU "Software\Hasbreo\OfficeFlow"
SectionEnd
