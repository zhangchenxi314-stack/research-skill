1|@echo off
2|setlocal enabledelayedexpansion
3|
4|echo.
5|echo ============================================
6|echo   Research Skill - Windows Deployment
7|echo ============================================
8|echo.
9|
10|:: ── 0. Detect project directory ──
11|set "PROJECT_DIR=%~dp0"
12|set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
13|echo Project: %PROJECT_DIR%
14|echo.
15|
16|:: ── 1. Check prerequisites ──
17|echo [1/5] Checking prerequisites...
18|echo.
19|
20|:: Hermes Agent
21|where hermes >nul 2>&1
22|if %ERRORLEVEL% NEQ 0 (
23|    echo   [FAIL] Hermes Agent not found in PATH
24|    echo          Install: https://hermes-agent.nousresearch.com/docs/
25|    goto :abort
26|)
27|echo   [ OK ] Hermes Agent
28|
29|:: agent-browser
30|where agent-browser >nul 2>&1
31|if %ERRORLEVEL% NEQ 0 (
32|    echo   [FAIL] agent-browser not found in PATH
33|    echo          Install: https://github.com/nousresearch/agent-browser
34|    goto :abort
35|)
36|echo   [ OK ] agent-browser
37|
38|:: Chrome for Testing
39|if not defined AGENT_BROWSER_EXECUTABLE_PATH (
40|    echo   [WARN] AGENT_BROWSER_EXECUTABLE_PATH not set
41|    echo          agent-browser needs Chrome for Testing.
42|    echo.
43|    echo   Common Chrome paths:
44|    echo     C:\Users\%USERNAME%\.agent-browser\chrome\chrome-win64\chrome.exe
45|    echo     C:\Program Files\Google\Chrome\Application\chrome.exe
46|    echo.
47|    echo   Set it manually or skip for now (skill will fail without it).
48|) else (
49|    echo   [ OK ] AGENT_BROWSER_EXECUTABLE_PATH = %AGENT_BROWSER_EXECUTABLE_PATH%
50|)
51|echo.
52|
53|:: ── 2. Create directories ──
54|echo [2/5] Creating directories...
55|if not exist "%PROJECT_DIR%\reports" mkdir "%PROJECT_DIR%\reports"
56|echo   [ OK ] reports/
57|echo.
58|
59|:: ── 3. Install skill to Hermes ──
60|echo [3/5] Installing skill to Hermes Agent...
61|set "SKILL_SRC=%PROJECT_DIR%\skills\research-report"
62|set "SKILL_DST=%USERPROFILE%\.hermes\skills\note-taking\research-report"
63|
64|if not exist "%SKILL_SRC%\SKILL.md" (
65|    echo   [FAIL] SKILL.md not found at %SKILL_SRC%
66|    echo          Make sure you copied the entire project folder.
67|    goto :abort
68|)
69|
70|:: Remove old install, copy fresh
71|if exist "%SKILL_DST%" rmdir /s /q "%SKILL_DST%"
72|xcopy "%SKILL_SRC%\*" "%SKILL_DST%\" /E /I /Q >nul
73|
74|:: Replace {PROJECT_DIR} placeholder
75|powershell -Command ^
76|    "$path = '%SKILL_DST%\\SKILL.md'; ^
77|     $c = Get-Content $path -Raw; ^
78|     $c = $c -replace '\{PROJECT_DIR\}', '%PROJECT_DIR:\=/%'; ^
79|     Set-Content $path -Value $c -Encoding UTF8 -NoNewline; ^
80|     Add-Content $path -Value \"`n\""
81|
82|echo   [ OK ] Installed to %SKILL_DST%
83|echo.
84|
85|:: ── 4. Verify installation ──
86|echo [4/5] Verifying installation...
87|if exist "%SKILL_DST%\SKILL.md" (
88|    findstr /c:"name: research-report" "%SKILL_DST%\SKILL.md" >nul
89|    if !ERRORLEVEL! EQU 0 (
90|        echo   [ OK ] SKILL.md valid
91|    ) else (
92|        echo   [WARN] SKILL.md may be invalid
93|    )
94|) else (
95|    echo   [FAIL] SKILL.md missing after install
96|    goto :abort
97|)
98|
99|if exist "%SKILL_DST%\references\agent-browser-guide.md" (
100|    echo   [ OK ] agent-browser-guide.md present
101|) else (
102|    echo   [WARN] agent-browser-guide.md missing
103|)
104|echo.
105|
106|:: ── 5. Summary ──
107|echo [5/5] Deployment complete.
108|echo.
109|echo ============================================
110|echo   Next Steps
111|echo ============================================
112|echo.
113|echo   1. Set AGENT_BROWSER_EXECUTABLE_PATH if not done:
114|echo      setx AGENT_BROWSER_EXECUTABLE_PATH "C:\path\to\chrome.exe"
115|echo.
116|echo   2. Open each target website in Chrome and log in once.
117|echo      The cookie session will be reused automatically.
118|echo.
119|echo   3. Edit config/sites.json to verify:
120|echo      - Login page URLs and selectors
121|echo      - Search page URLs and selectors
122|echo      - Keywords and schedule time
123|echo.
124|echo   4. Tell Hermes Agent to register the cron job:
125|echo      "Load research-report, then read sites.json
126|echo       and register the daily cron job."
127|echo.
128|echo ============================================
129|pause
130|exit /b 0
131|
132|:abort
133|echo.
134|echo ============================================
135|echo   Deployment ABORTED. Fix the issues above
136|echo   and run setup.bat again.
137|echo ============================================
138|pause
139|exit /b 1
140|