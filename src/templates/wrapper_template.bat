@echo off
for /f "delims=" %%a in ('C:\_noscan\software\nodejs18\node.exe "C:\_noscan\dev\github.com\magynhard\rvm-windows\src\wrapper\wrapper.js"') do set "return_value=%%a"
echo Returned value: %return_value%
call %return_value% %*
REM "C:\_noscan\software\Ruby32-x64\bin\ruby.exe" %*

REM "{{original_executable_path}}" %*