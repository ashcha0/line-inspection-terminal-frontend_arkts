@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: ===== 1. Set Core Paths =====
set "DEVECO_HOME=D:\Program Files\Huawei\DevEco Studio"
set "DEVECO_SDK_HOME=%DEVECO_HOME%\sdk"
set "NODE_PATH=%DEVECO_HOME%\tools\node\node.exe"
set "HVIGOR_SCRIPT=%DEVECO_HOME%\tools\hvigor\bin\hvigorw.js"
set "JAVA_HOME=D:\14730\Desktop\jdk\jdk-17.0.1"

:: ===== 2. Prepare environment =====
echo [INFO] Preparing environment...

:: ===== 3. Set Required Environment Variables =====
set "PATH=%JAVA_HOME%\bin;%DEVECO_SDK_HOME%\toolchains;%DEVECO_HOME%\tools;%PATH%"
set "OHOS_BASE=%DEVECO_SDK_HOME%\10.0"
set "HVIGOR_DIR=%DEVECO_HOME%\tools\hvigor"

:: ===== 4. Verify Path Existence =====
echo [INFO] Checking paths...
if not exist "!NODE_PATH!" (
    echo [ERROR] Node.js path not found: !NODE_PATH!
    exit /b 1
)
if not exist "!HVIGOR_SCRIPT!" (
    echo [ERROR] hvigor script not found: !HVIGOR_SCRIPT!
    exit /b 1
)
if not exist "!DEVECO_SDK_HOME!" (
    echo [ERROR] DevEco SDK path not found: !DEVECO_SDK_HOME!
    exit /b 1
)

:: ===== 5. Display Key Environment Variables =====
echo [INFO] DevEco SDK Path: !DEVECO_SDK_HOME!
echo [INFO] Node Path: !NODE_PATH!
echo [INFO] Java Path: !JAVA_HOME!\bin\java.exe
"!NODE_PATH!" --version
if exist "!JAVA_HOME!\bin\java.exe" (
    "!JAVA_HOME%\bin\java.exe" -version
) else (
    echo [WARNING] Java executable not found at "!JAVA_HOME!\bin\java.exe"
)

:: ===== 6. Execute Build Command =====
echo [INFO] Starting ArkTS project build...
echo Full command:
echo "!NODE_PATH!" "!HVIGOR_SCRIPT!" ^
--mode module ^
-p module=entry@default ^
-p product=default ^
-p pageType=page ^
-p compileResInc=true ^
-p requiredDeviceType=2in1 ^
-p previewMode=true ^
-p buildRoot=.preview ^
PreviewBuild ^
--watch --analyze=normal --parallel --incremental --daemon

echo.
echo ===== EXECUTION START =====
"!NODE_PATH!" "!HVIGOR_SCRIPT!" --mode module ^
  -p module=entry@default ^
  -p product=default ^
  -p pageType=page ^
  -p compileResInc=true ^
  -p requiredDeviceType=2in1 ^
  -p previewMode=true ^
  -p buildRoot=.preview ^
  PreviewBuild ^
  --watch --analyze=normal --parallel --incremental --daemon

:: Capture exit code
set "exit_code=!errorlevel!"
echo ===== EXECUTION FINISHED =====

:: ===== 7. Minimal Result Handling =====
if !exit_code! equ 0 (
    echo [SUCCESS] Build completed successfully!
) else (
    echo [ERROR] Build failed (error code: !exit_code!)
)

:: Clean exit without any pause
endlocal
exit /b %exit_code%