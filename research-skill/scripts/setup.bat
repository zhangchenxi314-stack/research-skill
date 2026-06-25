@echo off
setlocal enabledelayedexpansion

echo.
echo ============================================
echo   Research Skill - Windows Deployment
echo ============================================
echo.

:: ── 0. Detect project directory ──
set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
echo Project: %PROJECT_DIR%
echo.

:: ── 1. Check prerequisites ──
echo [1/5] Checking prerequisites...
echo.

:: Hermes Agent
where hermes >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   [FAIL] Hermes Agent not found in PATH
    echo          Install: https://hermes-agent.nousresearch.com/docs/
    goto :abort
)
echo   [ OK ] Hermes Agent

:: agent-browser
where agent-browser >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   [FAIL] agent-browser not found in PATH
    echo          Install: https://github.com/nousresearch/agent-browser
    goto :abort
)
echo   [ OK ] agent-browser

:: Chrome for Testing
if not defined AGENT_BROWSER_EXECUTABLE_PATH (
    echo   [WARN] AGENT_BROWSER_EXECUTABLE_PATH not set
    echo          agent-browser needs Chrome for Testing.
    echo.
    echo   Common Chrome paths:
    echo     C:\Users\%USERNAME%\.agent-browser\chrome\chrome-win64\chrome.exe
    echo     C:\Program Files\Google\Chrome\Application\chrome.exe
    echo.
    echo   Set it manually or skip for now (skill will fail without it).
) else (
    echo   [ OK ] AGENT_BROWSER_EXECUTABLE_PATH = %AGENT_BROWSER_EXECUTABLE_PATH%
)
echo.

:: ── 2. Create directories ──
echo [2/5] Creating directories...
if not exist "%PROJECT_DIR%\reports" mkdir "%PROJECT_DIR%\reports"
echo   [ OK ] reports/
echo.

:: ── 3. Install skill to Hermes ──
echo [3/5] Installing skill to Hermes Agent...
set "SKILL_SRC=%PROJECT_DIR%\skills\research-skill"
set "SKILL_DST=%USERPROFILE%\.hermes\skills\note-taking\research-skill"

if not exist "%SKILL_SRC%\SKILL.md" (
    echo   [FAIL] SKILL.md not found at %SKILL_SRC%
    echo          Make sure you copied the entire project folder.
    goto :abort
)

:: Remove old install, copy fresh
if exist "%SKILL_DST%" rmdir /s /q "%SKILL_DST%"
xcopy "%SKILL_SRC%\*" "%SKILL_DST%\" /E /I /Q >nul

:: Replace {PROJECT_DIR} placeholder
powershell -Command ^
    "$path = '%SKILL_DST%\\SKILL.md'; ^
     $c = Get-Content $path -Raw; ^
     $c = $c -replace '\{PROJECT_DIR\}', '%PROJECT_DIR:\=/%'; ^
     Set-Content $path -Value $c -Encoding UTF8 -NoNewline; ^
     Add-Content $path -Value \"`n\""

echo   [ OK ] Installed to %SKILL_DST%
echo.

:: ── 4. Verify installation ──
echo [4/5] Verifying installation...
if exist "%SKILL_DST%\SKILL.md" (
    findstr /c:"name: research-skill" "%SKILL_DST%\SKILL.md" >nul
    if !ERRORLEVEL! EQU 0 (
        echo   [ OK ] SKILL.md valid
    ) else (
        echo   [WARN] SKILL.md may be invalid
    )
) else (
    echo   [FAIL] SKILL.md missing after install
    goto :abort
)

if exist "%SKILL_DST%\references\agent-browser-guide.md" (
    echo   [ OK ] agent-browser-guide.md present
) else (
    echo   [WARN] agent-browser-guide.md missing
)
echo.

:: ── 5. Summary ──
echo [5/5] Deployment complete.
echo.
echo ============================================
echo   Next Steps
echo ============================================
echo.
echo   1. Set AGENT_BROWSER_EXECUTABLE_PATH if not done:
echo      setx AGENT_BROWSER_EXECUTABLE_PATH "C:\path\to\chrome.exe"
echo.
echo   2. Open each target website in Chrome and log in once.
echo      The cookie session will be reused automatically.
echo.
echo   3. Edit config/sites.json to verify:
echo      - Login page URLs and selectors
echo      - Search page URLs and selectors
echo      - Keywords and schedule time
echo.
echo   4. Tell Hermes Agent to register the cron job:
echo      "Load research-skill, then read sites.json
echo       and register the daily cron job."
echo.
echo ============================================
pause
exit /b 0

:abort
echo.
echo ============================================
echo   Deployment ABORTED. Fix the issues above
echo   and run setup.bat again.
echo ============================================
pause
exit /b 1
