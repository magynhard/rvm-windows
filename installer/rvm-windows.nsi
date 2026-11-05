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
  SetOutPath "$PLUGINSDIR\package"
  ClearErrors
  File /r "${PACKAGE_DIR}\*"
  IfErrors preflight_extract_failed
  SetOutPath "$PLUGINSDIR"
  File /oname=rvm-package-transaction.ps1 "..\src\tools\path\package_transaction.ps1"
  System::Call 'kernel32::SetEnvironmentVariable(t "RVM_ROOT", t "$INSTDIR")'
  nsExec::ExecToStack '"$PLUGINSDIR\package\bin\rvm.exe" --internal-version'
  Pop $0
  Pop $1
  ${If} $0 != 0
    MessageBox MB_ICONSTOP "Cannot start the new RVM executable (exit $0): $1. The existing installation was not replaced. Check Windows Security before retrying." /SD IDOK
    SetErrorLevel 1
    Abort
  ${EndIf}
  IfFileExists "$INSTDIR\.rvm-package-transaction" recover_package_transaction
  IfFileExists "$INSTDIR\.legacy-migration.json" recover_migration_only
  Goto prepare_migration
  recover_package_transaction:
    nsExec::ExecToStack 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PLUGINSDIR\rvm-package-transaction.ps1" -Action rollback -Target "$INSTDIR"'
    Pop $0
    Pop $1
    ${If} $0 != 0
      MessageBox MB_ICONSTOP "Automatic recovery could not restore the interrupted package transaction: $1. Preserve the recovery marker and backup; do not uninstall." /SD IDOK
      SetErrorLevel 1
      Abort
    ${EndIf}
    nsExec::ExecToStack '"$PLUGINSDIR\package\bin\rvm.exe" --internal-migration rollback'
    Pop $0
    Pop $1
    ${If} $0 != 0
      MessageBox MB_ICONSTOP "Package files were restored, but migration recovery failed: $1. Preserve the recovery backup and retry setup." /SD IDOK
      SetErrorLevel 1
      Abort
    ${EndIf}
    Delete "$INSTDIR\.rvm-package-transaction"
    Goto prepare_migration
  recover_migration_only:
    # A crash after migration prepare but before package snapshot did not alter
    # package files, so only its wrapper/config migration journal needs rollback.
    nsExec::ExecToStack '"$PLUGINSDIR\package\bin\rvm.exe" --internal-migration rollback'
    Pop $0
    Pop $1
    ${If} $0 != 0
      MessageBox MB_ICONSTOP "Could not recover the previous migration journal: $1. No package files were replaced." /SD IDOK
      SetErrorLevel 1
      Abort
    ${EndIf}
  prepare_migration:
  # Create recovery material before prepare or any package changes. It contains
  # a runnable rollback executable even if Defender removes the staged copy.
  ClearErrors
  GetTempFileName $4
  IfErrors recovery_backup_failed
  Delete "$4"
  CreateDirectory "$4"
  IfErrors recovery_backup_failed
  CopyFiles /SILENT "$PLUGINSDIR\rvm-package-transaction.ps1" "$4\package_transaction.ps1"
  IfErrors recovery_backup_failed
  CopyFiles /SILENT "$PLUGINSDIR\package\bin\rvm.exe" "$4\recovery-rvm.exe"
  IfErrors recovery_backup_failed
  nsExec::ExecToStack '"$4\recovery-rvm.exe" --internal-version'
  Pop $0
  Pop $1
  ${If} $0 != 0
    Goto recovery_backup_failed
  ${EndIf}
  SetOutPath "$INSTDIR"
  nsExec::ExecToStack '"$4\recovery-rvm.exe" --internal-migration prepare'
  Pop $0
  Pop $1
  ${If} $0 != 0
    RMDir /r "$4"
    MessageBox MB_ICONSTOP "Could not prepare installation migration (exit $0): $1. The existing installation was not replaced." /SD IDOK
    SetErrorLevel 1
    Abort
  ${EndIf}
  # Keep a durable per-file backup outside the install directory. It is never
  # removed automatically and remains available for interrupted-install recovery.
  nsExec::ExecToStack 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$4\package_transaction.ps1" -Action snapshot -Target "$INSTDIR" -Stage "$PLUGINSDIR\package" -Backup "$4"'
  Pop $0
  Pop $1
  ${If} $0 != 0
    Goto snapshot_failed
  ${EndIf}
  ClearErrors
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
    Goto deployment_failed
  deploy:
  nsExec::ExecToStack 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$4\package_transaction.ps1" -Action deploy -Target "$INSTDIR" -Stage "$PLUGINSDIR\package" -Backup "$4"'
  Pop $0
  Pop $1
  ${If} $0 != 0
    Goto deployment_failed
  ${EndIf}
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
    DetailPrint "Native RVM is installed; deferred legacy migration cleanup needs attention: $1"
  ${EndIf}
  ${If} $2 == 1
    Delete "$3"
  ${EndIf}
  Delete "$INSTDIR\.rvm-package-transaction"
  RMDir /r "$4"
  Goto install_done
  preflight_extract_failed:
    MessageBox MB_ICONSTOP "Could not extract the new RVM executable. The existing installation was not replaced. Check Windows Security before retrying." /SD IDOK
    SetErrorLevel 1
    Abort
  recovery_backup_failed:
    ${If} $4 != ""
      RMDir /r "$4"
    ${EndIf}
    MessageBox MB_ICONSTOP "Could not create or validate the installer recovery backup (exit $0): $1. The existing installation was not replaced." /SD IDOK
    SetErrorLevel 1
    Abort
  snapshot_failed:
    FileOpen $7 "$4\snapshot-error.txt" w
    IfErrors +3
    FileWrite $7 "Snapshot exit $0: $1"
    FileClose $7
    IfFileExists "$INSTDIR\.rvm-package-transaction" 0 snapshot_rollback_migration
    nsExec::ExecToStack 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PLUGINSDIR\rvm-package-transaction.ps1" -Action rollback -Target "$INSTDIR" -Backup "$4"'
    Pop $5
    Pop $6
    ${If} $5 != 0
      MessageBox MB_ICONSTOP "Package rollback failed: $6. Backup: $4" /SD IDOK
      SetErrorLevel 1
      Abort
    ${EndIf}
    Delete "$INSTDIR\.rvm-package-transaction"
  snapshot_rollback_migration:
    nsExec::ExecToStack '"$4\recovery-rvm.exe" --internal-migration rollback'
    Pop $5
    Pop $6
    ${If} $5 != 0
      MessageBox MB_ICONSTOP "Migration rollback failed: $6. Backup: $4" /SD IDOK
      SetErrorLevel 1
      Abort
    ${EndIf}
    MessageBox MB_ICONSTOP "Could not back up package files (exit $0): $1. Previous package files were restored." /SD IDOK
    SetErrorLevel 1
    Abort
  deployment_failed:
    nsExec::ExecToStack '"$4\recovery-rvm.exe" --internal-migration rollback'
    Pop $8
    Pop $9
    nsExec::ExecToStack 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$4\package_transaction.ps1" -Action rollback -Target "$INSTDIR" -Backup "$4"'
    Pop $5
    Pop $6
    ${If} $5 != 0
      MessageBox MB_ICONSTOP "Package rollback needs manual attention: $6. Backup: $4" /SD IDOK
      SetErrorLevel 1
      Abort
    ${EndIf}
    ${If} $8 != 0
      MessageBox MB_ICONSTOP "Package files were restored, but wrapper rollback needs manual attention: $9. Backup: $4" /SD IDOK
      SetErrorLevel 1
      Abort
    ${EndIf}
    ${If} $2 == 1
      ClearErrors
      CopyFiles /SILENT "$3" "$INSTDIR\bin\rvm.exe"
      IfErrors restore_failed
      MessageBox MB_ICONSTOP "Installation failed. The previous RVM executable was restored. Check Windows Security and retry after investigating." /SD IDOK
    ${Else}
      MessageBox MB_ICONSTOP "Installation failed. Check Windows Security before retrying." /SD IDOK
    ${EndIf}
    Delete "$INSTDIR\.rvm-package-transaction"
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
  Delete "$INSTDIR\src\tools\path\package_transaction.ps1"
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
