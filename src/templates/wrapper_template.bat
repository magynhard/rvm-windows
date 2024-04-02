@echo off
for /f "delims=" %%a in ('C:\_noscan\software\nodejs18\node.exe "C:\_noscan\dev\github.com\magynhard\rvm-windows\src\wrapper\wrapper_runner.js" "%CD%" %~n0') do set "return_value=%%a"
REM echo Returned value: %return_value%
call %return_value% %*