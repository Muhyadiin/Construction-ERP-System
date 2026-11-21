Unicode true
!include "MUI2.nsh"
Name "Kobci Construction ERP"
OutFile "Kobci-Construction-ERP-Windows-x64-Preview-2.exe"
InstallDir "$LOCALAPPDATA\Programs\Kobci Construction ERP"
RequestExecutionLevel user
SetCompressor zlib
ShowInstDetails show
!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\KobciConstructionERPPreview"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\..\LICENSE"
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\Kobci.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Open Kobci Construction ERP"
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Install"
  SetShellVarContext current
  ; WebView2 is included in current Windows installations. If absent, use
  ; Microsoft's authenticated per-user runtime installer before copying the ERP.
  SetRegView 32
  ReadRegStr $0 HKLM "Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
  StrCmp $0 "" 0 webview_ready
  ReadRegStr $0 HKCU "Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" "pv"
  StrCmp $0 "" 0 webview_ready
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"
  File "MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
  DetailPrint "Installing Microsoft Edge WebView2 Runtime"
  ClearErrors
  ExecWait '"$PLUGINSDIR\MicrosoftEdgeWebView2RuntimeInstallerX64.exe" /silent /install' $1
  IfErrors webview_missing
  IntCmp $1 0 webview_ready webview_missing webview_missing
webview_missing:
  MessageBox MB_OK|MB_ICONEXCLAMATION "Kobci needs Microsoft Edge WebView2 Runtime. The bundled runtime could not be installed. See the setup details, then retry." /SD IDOK
  SetErrorLevel 1
  Abort
webview_ready:
  SetOutPath "$INSTDIR\server"
  File /r "payload\server\*"
  SetOutPath "$INSTDIR"
  File "Kobci.exe"
  File "..\..\LICENSE"
  File "..\..\NOTICE"
  File "..\..\docs\legal\THIRD_PARTY_LICENSES.md"
  File "README.md"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName" "Kobci Construction ERP (Windows preview 2)"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion" "19.8.0-preview.2"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "Publisher" "Kobci Construction ERP"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair" 1
  SetOutPath "$LOCALAPPDATA\Kobci Construction ERP\Data"
  CreateDirectory "$SMPROGRAMS\Kobci Construction ERP"
  CreateShortCut "$SMPROGRAMS\Kobci Construction ERP\Kobci Construction ERP.lnk" "$INSTDIR\Kobci.exe"
SectionEnd

Section "Uninstall"
  SetShellVarContext current
  ; This generated list removes only files from the original build.
  !include "remove-server.nsh"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\Kobci.exe"
  Delete "$INSTDIR\NOTICE"
  Delete "$INSTDIR\THIRD_PARTY_LICENSES.md"
  Delete "$INSTDIR\README.md"
  Delete "$SMPROGRAMS\Kobci Construction ERP\Kobci Construction ERP.lnk"
  RMDir "$SMPROGRAMS\Kobci Construction ERP"
  DeleteRegKey HKCU "${UNINSTALL_KEY}"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
SectionEnd
