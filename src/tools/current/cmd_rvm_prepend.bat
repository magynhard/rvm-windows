@echo off
REM check if env RVM_CURRENT_SESSION is set already
if defined RVM_SESSION (
    REM do nothing
) else (
    REM generate unique id for current terminal
    set /a RVM_SESSION=%RANDOM% * 1000 + %TIME:~6,2%
)
