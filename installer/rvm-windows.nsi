Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"

!ifndef VERSION
  !define VERSION "1.1.1"
!endif
!ifndef FILE_VERSION
  !define FILE_VERSION "1.1.1.0"
!endif
!ifndef PACKAGE_DIR
  !define PACKAGE_DIR "..\dist\rvm-windows-${VERSION}-windows-x64"
!endif
!ifndef OUTPUT_FILE
  !define OUTPUT_FILE "..\dist\rvm-windows-${VERSION}-windows-x64-setup.exe"
!endif

!define PUBLISHER "Matth${U+00E4}us J. N. Beyrle"
VIProductVersion "${FILE_VERSION}"
VIAddVersionKey /LANG=0 "ProductName" "rvm-windows"
VIAddVersionKey /LANG=0 "ProductVersion" "${VERSION}"
VIAddVersionKey /LANG=0 "FileVersion" "${FILE_VERSION}"
VIAddVersionKey /LANG=0 "FileDescription" "Ruby Version Manager for Windows Setup"
VIAddVersionKey /LANG=0 "CompanyName" "${PUBLISHER}"
VIAddVersionKey /LANG=0 "LegalCopyright" "Copyright (c) 2024 ${PUBLISHER}"

Name "rvm-windows ${VERSION} (Ruby Version Manager 4 Windows)"
OutFile "${OUTPUT_FILE}"
InstallDir "$LOCALAPPDATA\Programs\rvm-windows"
InstallDirRegKey HKCU "Software\rvm-windows.cr" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma
!define MUI_ABORTWARNING
!define MUI_ICON "..\src\assets\img\rvm-windows.ico"
!define MUI_UNICON "..\src\assets\img\rvm-windows.ico"
!insertmacro MUI_PAGE_WELCOME
# LICENSE carries a UTF-8 BOM so NSIS does not interpret its text as ANSI.
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
  # Validate the new executable before touching an existing installation.
  # Security software may quarantine an extracted executable immediately.
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"
  ClearErrors
  File /oname=rvm-preflight.exe "${PACKAGE_DIR}\bin\rvm.exe"
  IfErrors preflight_extract_failed
  System::Call 'kernel32::SetEnvironmentVariable(t "RVM_ROOT", t "$INSTDIR")'
  nsExec::ExecToStack '"$PLUGINSDIR\rvm-preflight.exe" --internal-version'
  Pop $0
  Pop $1
  ${If} $0 != 0
    MessageBox MB_ICONSTOP "Cannot start the new RVM executable (exit $0): $1. The existing installation was not replaced. Check Windows Security before retrying." /SD IDOK
    SetErrorLevel 1
    Abort
  ${EndIf}
  SetOutPath "$INSTDIR"
  nsExec::ExecToStack '"$PLUGINSDIR\rvm-preflight.exe" --internal-migration prepare'
  Pop $0
  Pop $1
  ${If} $0 != 0
    MessageBox MB_ICONSTOP "Could not prepare installation migration (exit $0): $1. The existing installation was not replaced." /SD IDOK
    SetErrorLevel 1
    Abort
  ${EndIf}
  # Back up the old executable separately before deploying package files.
  StrCpy $2 0
  IfFileExists "$INSTDIR\bin\rvm.exe" 0 deploy
    ClearErrors
    GetTempFileName $3
    IfErrors backup_failed
    CopyFiles /SILENT "$INSTDIR\bin\rvm.exe" "$3"
    IfErrors backup_failed
    StrCpy $2 1
    Goto deploy
  backup_failed:
    nsExec::Exec '"$PLUGINSDIR\rvm-preflight.exe" --internal-migration rollback'
    MessageBox MB_ICONSTOP "Could not back up the existing RVM executable. The installation was not replaced." /SD IDOK
    SetErrorLevel 1
    Abort
  deploy:
  SetOverwrite on
  ClearErrors
  File /r "${PACKAGE_DIR}\*"
  IfErrors deployment_failed
  nsExec::ExecToStack '"$INSTDIR\bin\rvm.exe" --internal-version'
  Pop $0
  Pop $1
  ${If} $0 != 0
    Goto deployment_failed
  ${EndIf}
  nsExec::ExecToStack '"$INSTDIR\bin\rvm.exe" --internal-install'
  Pop $0
  Pop $1
  ${If} $0 != 0
    Goto deployment_failed
  ${EndIf}
  # Read the UTF-8 JSON in PowerShell instead of round-tripping a Unicode path
  # through the NSIS process-output code page.
  ExecWait 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\src\tools\path\package_path.ps1" -InstallRoot "$INSTDIR"' $0
  ${If} $0 != 0
    Goto deployment_failed
  ${EndIf}
  WriteRegStr HKCU "Software\rvm-windows.cr" "InstallDir" "$INSTDIR"
  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr" "DisplayName" "rvm-windows (Ruby Version Manager 4 Windows)"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr" "Publisher" "${PUBLISHER}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr" "DisplayIcon" '$\"$INSTDIR\uninstall.exe$\",0'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr" "UninstallString" '$\"$INSTDIR\uninstall.exe$\"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr" "QuietUninstallString" '$\"$INSTDIR\uninstall.exe$\" /S'
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr" "NoModify" 1
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr" "NoRepair" 1
  # Cleanup is deferred until active legacy/npm operations have exited. The
  # migration class never uninstalls the current npm installation bridge.
  nsExec::ExecToStack '"$INSTDIR\bin\rvm.exe" --internal-migration commit'
  Pop $0
  Pop $1
  ${If} $0 != 0
    DetailPrint "Native RVM installed; legacy cleanup needs attention: $1"
  ${EndIf}
  ${If} $2 == 1
    Delete "$3"
  ${EndIf}
  Goto install_done
  preflight_extract_failed:
    MessageBox MB_ICONSTOP "Could not extract the new RVM executable. The existing installation was not replaced. Check Windows Security before retrying." /SD IDOK
    SetErrorLevel 1
    Abort
  deployment_failed:
    nsExec::Exec '"$PLUGINSDIR\rvm-preflight.exe" --internal-migration rollback'
    ${If} $2 == 1
      ClearErrors
      CopyFiles /SILENT "$3" "$INSTDIR\bin\rvm.exe"
      IfErrors restore_failed
      MessageBox MB_ICONSTOP "Installation failed. The previous RVM executable was restored. Check Windows Security and retry after investigating." /SD IDOK
    ${Else}
      MessageBox MB_ICONSTOP "Installation failed. Check Windows Security before retrying." /SD IDOK
    ${EndIf}
    SetErrorLevel 1
    Abort
  restore_failed:
    MessageBox MB_ICONSTOP "Installation failed and the previous executable could not be restored. The backup remains at $3." /SD IDOK
    SetErrorLevel 1
    Abort
  install_done:
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
  Delete "$INSTDIR\CONTRIBUTING.md"
  Delete "$INSTDIR\CHANGELOG.md"
  Delete "$INSTDIR\.legacy-migration.json"
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
  Delete "$INSTDIR\doc\img\RVM4Windows.svg"
  Delete "$INSTDIR\doc\img\RVM4Windows-wordmark.svg"
  Delete "$INSTDIR\doc\img\rvm-windows-icon.svg"
  Delete "$INSTDIR\doc\img\rvm-windows-icon.png"
  Delete "$INSTDIR\doc\img\rvm-windows.ico"
  Delete "$INSTDIR\src\assets\img\rvm-windows-icon.svg"
  Delete "$INSTDIR\src\assets\img\rvm-windows-icon.png"
  Delete "$INSTDIR\src\assets\img\rvm-windows.ico"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR\src\templates"
  RMDir "$INSTDIR\src\tools\current"
  RMDir "$INSTDIR\src\tools\path"
  RMDir "$INSTDIR\src\tools"
  RMDir "$INSTDIR\src\assets\img"
  RMDir "$INSTDIR\src\assets"
  RMDir "$INSTDIR\src"
  RMDir "$INSTDIR\bin"
  RMDir "$INSTDIR\doc\img"
  RMDir "$INSTDIR\doc"
  RMDir "$INSTDIR"
  DeleteRegKey HKCU "Software\rvm-windows.cr"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\rvm-windows.cr"
SectionEnd
