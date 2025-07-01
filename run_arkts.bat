@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: ===== 1. Set Core Paths =====
set "DEVECO_HOME=D:\Program Files\Huawei\DevEco Studio"
set "DEVECO_SDK_HOME=%DEVECO_HOME%\sdk"
set "NODE_PATH=%DEVECO_HOME%\tools\node\node.exe"
set "HVIGOR_SCRIPT=%DEVECO_HOME%\tools\hvigor\bin\hvigorw.js"
set "JAVA_HOME=D:\14730\Desktop\jdk\jdk-17.0.1"

:: ===== 2. Set Required Environment Variables =====
set "PATH=%JAVA_HOME%\bin;%DEVECO_SDK_HOME%\toolchains;%DEVECO_HOME%\tools;%PATH%"
set "OHOS_BASE=%DEVECO_SDK_HOME%\10.0"
set "HVIGOR_DIR=%DEVECO_HOME%\tools\hvigor"

:: ===== 3. Execute Clean Build Command =====
echo [INFO] Starting clean build...
echo Full command:
echo "!NODE_PATH!" "!HVIGOR_SCRIPT!" clean build 

echo.
echo ===== EXECUTION START =====
"!NODE_PATH!" "!HVIGOR_SCRIPT!" clean build

:: Capture exit code
set "exit_code=!errorlevel!"
echo ===== EXECUTION FINISHED =====

:: ===== 4. Result Handling =====
if !exit_code! equ 0 (
    echo [SUCCESS] Build completed successfully!
    echo You can now open the project in DevEco Studio for preview and other development tasks.
    endlocal
    exit /b 0
) else (
    echo.
    echo [ERROR] Build failed (error code: !exit_code!)
    echo.
    echo Possible reasons:
    echo 1. Incorrect SDK path configuration
    echo 2. Missing project dependencies
    echo 3. Node or Java version incompatibility
    echo 4. Project configuration errors
    echo.
    echo Suggested solutions:
    echo - Check SDK installation in DevEco Studio SDK Manager
    echo - Verify path: "!DEVECO_SDK_HOME!"
    echo - Try rebuilding in DevEco Studio first
    echo - Run 'hvigor clean' before rebuilding
    echo.
    pause
    endlocal
    exit /b !exit_code!
)