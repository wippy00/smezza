@echo off
REM Script per estrarre il database SQLite dall'app Android

echo.
echo ===== ESTRAZIONE DATABASE SMEZZA =====
echo.

REM Trova ADB da Flutter
where flutter >nul 2>nul
if %errorlevel%==0 (
    set ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
    if not exist "%ADB_PATH%" (
        echo Cerca ADB in altri percorsi...
        set ADB_PATH=%ANDROID_HOME%\platform-tools\adb.exe
    )
) else (
    echo Flutter non trovato nel PATH
    exit /b 1
)

if not exist "%ADB_PATH%" (
    echo ADB non trovato. Assicurati che Android SDK sia installato.
    echo Percorso previsto: %ADB_PATH%
    exit /b 1
)

echo ADB trovato: %ADB_PATH%
echo.

REM Estrai il database
echo Estraendo database...
"%ADB_PATH%" shell "run-as com.example.smezza cat /data/data/com.example.smezza/databases/expenses.db" > expenses.db

if exist expenses.db (
    echo ✅ Database estratto con successo: expenses.db
    echo.
    echo Puoi ora aprire expenses.db con:
    echo   - DB Browser for SQLite ^(https://sqlitebrowser.org/^)
    echo   - VS Code con estensione SQLite
    echo   - Online: https://sqliteviewer.app/
) else (
    echo ❌ Errore nell'estrazione del database
)

pause