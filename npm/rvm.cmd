@echo off
chcp 65001 > NUL
call "%~dp0src\tools\current\cmd_rvm_prepend.bat"
setlocal
if not exist "%~dp0install-root.txt" (
  echo Native RVM setup has not run. Run powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -Manual 1>&2
  exit /b 1
)
set "RVM_ROOT="
for /f "usebackq delims=" %%R in ("%~dp0install-root.txt") do set "RVM_ROOT=%%R"
if not exist "%RVM_ROOT%\bin\rvm.exe" (
  echo Native RVM is missing. Rerun "%~dp0install.ps1" -Manual or reinstall using setup. 1>&2
  exit /b 1
)
call "%RVM_ROOT%\rvm.cmd" %*
exit /b %ERRORLEVEL%
