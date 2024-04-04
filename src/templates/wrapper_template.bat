@echo off
set "ORIGINAL_PROXY=%HTTP_PROXY%"
set "ORIGINAL_RUBYPATH=%RUBYPATH%"

set "NODE_JS_RUNTIME_PATH={{node_js_runtime_path}}"
set "RVM_ROOT_PATH={{rvm_root_dir}}"

REM PATH: prepend wrapper
for /f "delims=" %%p in ('%NODE_JS_RUNTIME_PATH% "%RVM_ROOT_PATH%\src\wrapper\wrapper_path.js" "%CD%" %~n0') do set "return_path=%%p"
REM echo Returned path: "%return_path%"
call %return_path%

REM RUBYPATH
for /f "delims=" %%a in ('%NODE_JS_RUNTIME_PATH% "%RVM_ROOT_PATH%\src\wrapper\wrapper_rubypath.js" "%CD%" %~n0') do set "return_rubypath=%%a"
REM echo Returned path: "%return_rubypath%"
call %return_rubypath%

REM PROXY
for /f "delims=" %%b in ('%NODE_JS_RUNTIME_PATH% "%RVM_ROOT_PATH%\src\wrapper\wrapper_proxy.js" "%CD%" %~n0') do set "return_proxy=%%b"
REM echo Returned proxy: "%return_proxy%"
if not "%return_proxy%" == "" (
	set "HTTP_PROXY=%return_proxy%"
	set "HTTPS_PROXY=%return_proxy%"
	set "http_proxy=%return_proxy%"
	set "https_proxy=%return_proxy%"
)

REM FINAL COMMAND
for /f "delims=" %%c in ('%NODE_JS_RUNTIME_PATH% "%RVM_ROOT_PATH%\src\wrapper\wrapper_runner.js" "%CD%" %~n0') do set "return_value=%%c"
REM echo Returned value: "%return_value%"
call %return_value% %*

REM reset variables
set "HTTP_PROXY=%ORIGINAL_PROXY%"
set "HTTPS_PROXY=%ORIGINAL_PROXY%"
set "http_proxy=%ORIGINAL_PROXY%"
set "https_proxy=%ORIGINAL_PROXY%"
set "RUBYPATH=%ORIGINAL_RUBYPATH%"