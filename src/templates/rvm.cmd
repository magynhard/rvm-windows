@echo off
call "%~dp0src\tools\current\cmd_rvm_prepend.bat"
if /I "%~1"=="get" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0rvm.ps1" %*
    exit /b
)
"%~dp0bin\rvm.exe" %*
exit /b %ERRORLEVEL%
