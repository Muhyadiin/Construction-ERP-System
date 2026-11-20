Unicode true
!include "MUI2.nsh"
Name "Kobci Construction ERP"
OutFile "Kobci-Construction-ERP-Windows-x64-Preview-1.exe"
InstallDir "$LOCALAPPDATA\Programs\Kobci Construction ERP"
RequestExecutionLevel user
SetCompressor zlib
ShowInstDetails show
!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\KobciConstructionERPPreview"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\..\LICENSE"
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Install"
  SetShellVarContext current
  SetOutPath "$INSTDIR\server"
  File /r "payload\server\*"
  SetOutPath "$INSTDIR"
  File "..\..\LICENSE"
  File "..\..\NOTICE"
  File "..\..\docs\legal\THIRD_PARTY_LICENSES.md"
  File "README.md"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName" "Kobci Construction ERP (Windows preview 1)"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion" "19.8.0-preview.1"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "Publisher" "Kobci Construction ERP"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair" 1
  SetOutPath "$LOCALAPPDATA\Kobci Construction ERP\Data"
  CreateDirectory "$SMPROGRAMS\Kobci Construction ERP"
  CreateShortCut "$SMPROGRAMS\Kobci Construction ERP\Kobci Construction ERP.lnk" "$INSTDIR\server\openconstructionerp-server.exe" 'serve --host 127.0.0.1 --port 8765 --no-demo --open --data-dir "$OUTDIR"'
SectionEnd

Section "Uninstall"
  SetShellVarContext current
  ; This generated list removes only files from the original build.
  !include "remove-server.nsh"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\NOTICE"
  Delete "$INSTDIR\THIRD_PARTY_LICENSES.md"
  Delete "$INSTDIR\README.md"
  Delete "$SMPROGRAMS\Kobci Construction ERP\Kobci Construction ERP.lnk"
  RMDir "$SMPROGRAMS\Kobci Construction ERP"
  DeleteRegKey HKCU "${UNINSTALL_KEY}"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
SectionEnd
