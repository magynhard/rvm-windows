 @echo off
 REM use UTF8
 chcp 65001 > NUL

 SET "ORIGINAL_HTTP_PROXY=%HTTP_PROXY%"
 SET "ORIGINAL_HTTPS_PROXY=%HTTPS_PROXY%"
 SET "ORIGINAL_RUBYPATH=%RUBYPATH%"
 SET "ORIGINAL_PATH=%PATH%"

 SET "NODE_JS_RUNTIME_PATH={{node_js_runtime_path}}"
 SET "RVM_ROOT_PATH={{rvm_root_dir}}"

 REM PATH: prepend wrapper
 for /f "delims=" %%p in ('%NODE_JS_RUNTIME_PATH% "%RVM_ROOT_PATH%\src\wrapper\wrapper_path.js" "%CD%" %~n0') do SET "return_path=%%p"
 REM echo Returned path: "%return_path%"
 call %return_path%

 REM RUBYPATH
 for /f "delims=" %%a in ('%NODE_JS_RUNTIME_PATH% "%RVM_ROOT_PATH%\src\wrapper\wrapper_rubypath.js" "%CD%" %~n0') do SET "return_rubypath=%%a"
 REM echo Returned path: "%return_rubypath%"
 call %return_rubypath%

 REM PROXY
 for /f "delims=" %%b in ('%NODE_JS_RUNTIME_PATH% "%RVM_ROOT_PATH%\src\wrapper\wrapper_proxy.js" "%CD%" %~n0') do SET "return_proxy=%%b"
 REM echo Returned proxy: "%return_proxy%"
 if not "%return_proxy%" == "" (
 	SET "HTTP_PROXY=%return_proxy%"
 	SET "HTTPS_PROXY=%return_proxy%"
 	SET "http_proxy=%return_proxy%"
 	SET "https_proxy=%return_proxy%"
 )

 REM FINAL COMMAND
 for /f "delims=" %%c in ('%NODE_JS_RUNTIME_PATH% "%RVM_ROOT_PATH%\src\wrapper\wrapper_runner.js" "%CD%" %~n0') do SET "return_value=%%c"
 REM echo Returned value: "%return_value%"
 CALL %return_value% %*

 REM reSET variables
 SET "HTTP_PROXY=%ORIGINAL_HTTP_PROXY%"
 SET "HTTPS_PROXY=%ORIGINAL_HTTPS_PROXY%"
 SET "RUBYPATH=%ORIGINAL_RUBYPATH%"
 SET "PATH=%ORIGINAL_PATH%"

 REM AFTER COMMAND
 %NODE_JS_RUNTIME_PATH% "%RVM_ROOT_PATH%\src\wrapper\wrapper_after.js" "%CD%" %~n0