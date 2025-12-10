@echo off

IF NOT EXIST "%XCOM2SDKPATH%\Development\SrcOrig" (
    echo You need to specify the location of the XCOM 2 WOTC SDK (typically ^<path to Steam^>\steamapps\common\XCOM 2 War of the Chosen SDK^) in the XCOM2SDKPATH environment variable
    exit /b 1
)

IF NOT EXIST "%XCOM2GAMEPATH%\Binaries\Win64\XCom2.exe" (
    echo You need to specify the location of the XCOM 2 War of the Chosen game directory (typically ^<path to Steam^>\steamapps\common\XCOM 2\XCom2-WarOfTheChosen^) in the XCOM2GAMEPATH environment variable
    exit /b 1
)

rem The trailing backslash after %~dp0 is important, otherwise PowerShell thinks the " is being escaped!
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted  -file "%~dp0.scripts\build.ps1" -srcDirectory "%~dp0\" -sdkPath "%XCOM2SDKPATH%" -gamePath "%XCOM2GAMEPATH%" %*
