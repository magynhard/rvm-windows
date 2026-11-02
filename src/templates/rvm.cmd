@echo off
call "%~dp0src\tools\current\cmd_rvm_prepend.bat"
"%~dp0bin\rvm.exe" %*
exit /b %ERRORLEVEL%
