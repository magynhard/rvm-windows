@ECHO OFF
REM use UTF8
chcp 65001 > NUL
REM usage: prepend_user_path.bat "C:\\example\path"
SET Key="HKCU\Environment"
FOR /F "usebackq tokens=2*" %%A IN (`REG QUERY %Key% /v PATH`) DO Set CurrPath=%%B
REM ECHO %CurrPath% > user_path_bak.txt
SETX PATH %1;"%CurrPath%"
SET PATH=%1;"%CurrPath%"