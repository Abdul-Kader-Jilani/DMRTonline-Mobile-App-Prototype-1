@echo off
setlocal enabledelayedexpansion
title DMRT Online - Push Mobile App to GitHub

echo =====================================================================
echo  DMRT Online Mobile App - Push to GitHub
echo =====================================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "PORTABLE_GIT=%SCRIPT_DIR%..\toolchains\PortableGit\cmd\git.exe"

if exist "%PORTABLE_GIT%" (
    set "GIT_CMD=%PORTABLE_GIT%"
) else (
    set "GIT_CMD=git"
)

echo [1/3] Checking working directory status...
"%GIT_CMD%" status --short
echo.

"%GIT_CMD%" diff-index --quiet HEAD --
if %ERRORLEVEL% neq 0 (
    echo [2/3] Detected uncommitted changes. Staging and committing...
    "%GIT_CMD%" add .
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
    set "TIMESTAMP=!datetime:~0,4!-!datetime:~4,2!-!datetime:~6,2! !datetime:~8,2!:!datetime:~10,2!"
    "%GIT_CMD%" commit -m "chore(sync): automated mobile app snapshot at !TIMESTAMP!"
) else (
    echo [2/3] Working tree clean. No new local files to commit.
)
echo.

echo [3/3] Pushing commits to GitHub (origin main)...
"%GIT_CMD%" push -u origin main

if %ERRORLEVEL% equ 0 (
    echo.
    echo =====================================================================
    echo  SUCCESS! Mobile App commits pushed to GitHub successfully.
    echo =====================================================================
) else (
    echo.
    echo =====================================================================
    echo  [NOTICE] Push did not complete automatically.
    echo  Please check your internet connection or GitHub repository access.
    echo =====================================================================
)

echo.
pause
