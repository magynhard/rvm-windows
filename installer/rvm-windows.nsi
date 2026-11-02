Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"

!ifndef VERSION
  !define VERSION "1.0.8"
!endif
!ifndef PACKAGE_DIR
  !define PACKAGE_DIR "..\dist\rvm-windows-${VERSION}-windows-x64"
!endif

Name "rvm-windows ${VERSION} (Crystal)"
OutFile "..\dist\rvm-windows-${VERSION}-windows-x64-setup.exe"
InstallDir "$LOCALAPPDATA\Programs\rvm-windows"
InstallDirRegKey HKCU "Software\rvm-windows.cr" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma
!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_ICONSTOP "rvm-windows requires 64-bit Windows."
    Abort
  ${EndIf}
FunctionEnd

Section "rvm-windows" Main
  SetRegView 64
  SetOutPath "$INSTDIR"
  SetOverwrite on
  File /r "${PACKAGE_DIR}\*"
  # Bypass normal startup: preserve config and installed Ruby paths, regenerate
  # wrappers for this executable, but do not scan, kill MSYS or run installers.
  System::Call 'kernel32::SetEnvironmentVariable(t "RVM_ROOT", t "$INSTDIR")'
  nsExec::ExecToStack '"$INSTDIR\bin\rvm.exe" --internal-install'
  Pop $0
  Pop $1
  ${If} $0 != 0
    MessageBox MB_ICONSTOP "Could not initialize RVM wrappers: $1"
    SetErrorLevel 1
    Abort
  ${EndIf}
  # Read the UTF-8 JSON in PowerShell instead of round-tripping a Unicode path
  # through the NSIS process-output code page.
  ExecWait 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\src\tools\path\package_path.ps1" -InstallRoot "$INSTDIR"' $0
  ${If} $0 != 0
    MessageBox MB_ICONSTOP "Could not update user PATH. Run rvm init manually."
    SetErrorLevel 1
    Abort
  ${EndIf}
  WriteRegStr HKCU "Software\rvm-windows.cr" "InstallDir" "$INSTDIR"
  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr" "DisplayName" "rvm-windows (Crystal)"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr" "UninstallString" '$\"$INSTDIR\uninstall.exe$\"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr" "QuietUninstallString" '$\"$INSTDIR\uninstall.exe$\" /S'
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr" "NoRepair" 1
SectionEnd

Section "Uninstall"
  SetRegView 64
  System::Call 'kernel32::SetEnvironmentVariable(t "RVM_ROOT", t "$INSTDIR")'
  ExecWait '"$INSTDIR\bin\rvm.exe" --internal-uninstall'
  ExecWait 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\src\tools\path\package_path.ps1" -InstallRoot "$INSTDIR" -Remove'
  # Only package-owned files. Never delete ~/.rvm*, Ruby installations or caches.
  Delete "$INSTDIR\bin\rvm.exe"
  Delete "$INSTDIR\rvm.cmd"
  Delete "$INSTDIR\rvm.ps1"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\README.md"
  Delete "$INSTDIR\CHANGELOG.md"
  Delete "$INSTDIR\src\templates\.rvm.json"
  Delete "$INSTDIR\src\templates\wrapper_template.bat"
  Delete "$INSTDIR\src\templates\rvm.cmd"
  Delete "$INSTDIR\src\templates\rvm.ps1"
  Delete "$INSTDIR\src\tools\current\cmd_rvm_prepend.bat"
  Delete "$INSTDIR\src\tools\current\ps_rvm_prepend.ps1"
  Delete "$INSTDIR\src\tools\path\get_user_path.bat"
  Delete "$INSTDIR\src\tools\path\prepend_user_path.bat"
  Delete "$INSTDIR\src\tools\path\info.txt"
  Delete "$INSTDIR\src\tools\path\package_path.ps1"
  Delete "$INSTDIR\doc\PORTING.md"
  Delete "$INSTDIR\doc\VALIDATION.md"
  Delete "$INSTDIR\doc\developer.md"
  Delete "$INSTDIR\doc\img\rvm_cmd_logo.png"
  Delete "$INSTDIR\doc\img\rvm_cmd_logo_round.png"
  Delete "$INSTDIR\doc\img\rvm_cmd_logo_square.png"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR\src\templates"
  RMDir "$INSTDIR\src\tools\current"
  RMDir "$INSTDIR\src\tools\path"
  RMDir "$INSTDIR\src\tools"
  RMDir "$INSTDIR\src"
  RMDir "$INSTDIR\bin"
  RMDir "$INSTDIR\doc\img"
  RMDir "$INSTDIR\doc"
  RMDir "$INSTDIR"
  DeleteRegKey HKCU "Software\rvm-windows.cr"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr"
SectionEnd
