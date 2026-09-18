@echo off
setlocal enabledelayedexpansion
title DMRT Online - 1-Click Phone Update and Deploy

echo =====================================================================
echo    DMRT Online Mobile App - 1-Click Phone Update and Deploy
echo =====================================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "TOOLCHAIN_SCRIPT=%SCRIPT_DIR%..\toolchains\flutter_env.cmd"
set "ADB_EXE=%SCRIPT_DIR%..\toolchains\android-sdk\platform-tools\adb.exe"
set "APK_PATH=%SCRIPT_DIR%build\app\outputs\flutter-apk\app-debug.apk"

set "DART_SUPPRESS_ANALYTICS=true"
set "FLUTTER_SUPPRESS_ANALYTICS=true"

cd /d "%SCRIPT_DIR%"

REM 1. Display connected devices
echo [1/3] Checking connected Android devices...
if exist "%ADB_EXE%" (
    "%ADB_EXE%" devices
) else (
    adb devices
)
echo.

REM 2. Compile Debug APK
echo [2/3] Compiling Flutter Debug APK for Android...
if exist "%TOOLCHAIN_SCRIPT%" (
    call "%TOOLCHAIN_SCRIPT%" build apk --debug
) else (
    call flutter build apk --debug
)

if errorlevel 1 (
    echo.
    echo [ERROR] Flutter build failed with exit code %ERRORLEVEL%.
    echo Please review the build errors above.
    echo.
    pause
    exit /b %ERRORLEVEL%
)

if not exist "%APK_PATH%" (
    echo.
    echo [ERROR] Compiled APK not found at: "%APK_PATH%"
    echo.
    pause
    exit /b 1
)

REM 3. Install APK to Connected Phone
echo.
echo [3/3] Installing APK onto your phone and launching...
if exist "%ADB_EXE%" (
    "%ADB_EXE%" install -r "%APK_PATH%"
) else (
    adb install -r "%APK_PATH%"
)

if errorlevel 1 (
    echo.
    echo =====================================================================
    echo  [FAILED] Could not install to phone.
    echo =====================================================================
    echo  Reason: No authorized Android phone was detected by ADB.
    echo.
    echo  To fix this:
    echo    1. Plug your Android phone into this PC using a USB cable.
    echo    2. Enable "USB Debugging" in Settings ^> Developer Options.
    echo    3. Unlock your phone and tap "Allow USB Debugging" on the pop-up.
    echo    4. Set USB mode to "File Transfer / MTP" instead of "Charging only".
    echo =====================================================================
    echo.
    pause
    exit /b 1
)

REM 4. Launch App
if exist "%ADB_EXE%" (
    "%ADB_EXE%" shell am start -n com.dmrt.online/com.dmrt.dmrt_online.MainActivity
) else (
    adb shell am start -n com.dmrt.online/com.dmrt.dmrt_online.MainActivity
)

echo.
echo =====================================================================
echo  SUCCESS! DMRT Online updated and launched on your phone.
echo =====================================================================
echo.
pause
exit /b 0
