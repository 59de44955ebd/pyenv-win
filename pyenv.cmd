@echo off

rem simple check if we are in powershell (fallible)
echo %PSModulePath% | findstr %USERPROFILE% >nul
if %ERRORLEVEL% == 0 (
	powershell pyenv.ps1 %*
	goto :eof
)


set PYENV_VERSION=0.1
set PYENV_DIR=%~dp0
set PYENV_DIR=%PYENV_DIR:~0,-1%

if not exist "%PYENV_DIR%\versions_dir.txt" (
	exit /b
)

for /F "usebackq delims=" %%a in (`type "%PYENV_DIR%\versions_dir.txt"`) do (
	set PYTHON_VERSION_DIR=%%a
)

if "%PYTHON_VERSION_DIR%" == "" (
	exit /b
)

rem pyenv versions
if "%1" == "versions" (
	call :versions
	goto :eof
)

rem pyenv local 3.12.4
if "%1" == "local" if "%2" neq "" (
	call :local %2
	goto :eof
)

rem pyenv global 3.12.4
if "%1" == "global" if "%2" neq "" (
	call :global %2
	goto :eof
)

rem pyenv list
if "%1" == "list" (
	type %PYENV_DIR%\versions_list.txt
	goto :eof
)

rem pyenv install 3.12.4
if "%1" == "install" if "%2" neq "" (
	powershell pyenv.ps1 %*
	goto :eof
)

rem pyenv uninstall 3.12.4
if "%1" == "uninstall" if "%2" neq "" (
	powershell pyenv.ps1 %*
	goto :eof
)

rem pyenv update-list
if "%1" == "update-list" (
	powershell pyenv.ps1 %*
	goto :eof
)

rem pyenv pip-upgrade-all
if "%1" == "pip-upgrade-all" (
	call :pip_upgrade_all
	goto :eof
)

rem pyenv uninstall 3.12.4
if "%1" == "pip-transfer" if "%2" neq "" if "%3" neq "" (
	call :pip_transfer %2 %3
	goto :eof
)

rem no or unknown command
echo.
echo Usage: pyenv ^<command^> [^<arguments^>]
echo.
echo Available commands:
echo ===================
echo.
echo install ^<version^>         Install a Python version (download from python.org)
echo.
echo uninstall ^<version^>       Uninstall a Python version
echo.
echo global ^<version^>          Change the globally active Python version
echo                           (updates environment variables in userspace registry)
echo.
echo local ^<version^>           Change the local active Python version
echo                           (only for the current CMD or Powershell instance)
echo.
echo versions                  List all Python versions currently installed via pyenv
echo.
echo list                      List all Python versions that can be installed
echo.
echo update-list               Update the list of installable Python versions available at python.org
echo.
echo pip-transfer ^<from^> ^<to^>  Utility, tries to install all packages of version ^<from^> in version ^<to^>
echo.
echo pip-upgrade-all           Utility, upgrades all outdated packages for the active Python version
echo.

goto :eof

rem ######################################
:local
rem ######################################
if exist "%PYTHON_VERSION_DIR%\%1\" (
	set PYTHONHOME=%PYTHON_VERSION_DIR%\%1
	call :refresh_env
	python -V
) else (
	echo [Error] Version not available
)
exit /b

rem ######################################
:global
rem ######################################
if exist "%PYTHON_VERSION_DIR%\%1\" (
	set PYTHONHOME=%PYTHON_VERSION_DIR%\%1
	setx PYTHONHOME %PYTHON_VERSION_DIR%\%1 >nul
	call :refresh_env
	python -V
) else (
	echo [Error] Version not available
)
exit /b

rem ######################################
:versions
rem ######################################
for /F "usebackq delims=" %%a in (`dir /b /ad "%PYTHON_VERSION_DIR%"`) do (
	if "%PYTHON_VERSION_DIR%\%%a" == "%PYTHONHOME%" (
		echo * %%a
	) else (
	    echo   %%a
	)
)
exit /b

rem ######################################
:refresh_env
rem ######################################
rem Only works in CMD, not PS!

echo Refreshing environment variables ...

echo/@echo off >"%TEMP%\_env.cmd"

rem Slowly generating final file
call :GetRegEnv "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" >> "%TEMP%\_env.cmd"
call :GetRegEnv "HKCU\Environment">>"%TEMP%\_env.cmd" >> "%TEMP%\_env.cmd"

rem Special handling for PATH - mix both User and System
call :SetFromReg "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" Path Path_HKLM >> "%TEMP%\_env.cmd"
echo set "PYTHONHOME=%PYTHONHOME%" >> "%TEMP%\_env.cmd"
call :SetFromReg "HKCU\Environment" Path Path_HKCU >> "%TEMP%\_env.cmd"

rem Caution: do not insert space-chars before >> redirection sign
echo/set "Path=%%Path_HKLM%%;%%Path_HKCU%%" >> "%TEMP%\_env.cmd"

rem capture user / architecture
SET "OriginalUserName=%USERNAME%"
SET "OriginalArchitecture=%PROCESSOR_ARCHITECTURE%"

rem Set these variables
call "%TEMP%\_env.cmd"

rem reset user / architecture
SET "USERNAME=%OriginalUserName%"
SET "PROCESSOR_ARCHITECTURE=%OriginalArchitecture%"

set Path_HKLM=
set Path_HKCU=

rem cleanup
del /f /q "%TEMP%\_env.cmd" 2>nul
del /f /q "%TEMP%\_envset.tmp" 2>nul
del /f /q "%TEMP%\_envget.tmp" 2>nul

exit /b

rem Set one environment variable from registry key
rem ######################################
:SetFromReg
rem ######################################
"%WinDir%\System32\Reg" query "%~1" /v "%~2" > "%TEMP%\_envset.tmp" 2>NUL
for /f "usebackq skip=2 tokens=2,*" %%A in ("%TEMP%\_envset.tmp") do (
    echo/set "%~3=%%B"
)
exit /b

rem Get a list of environment variables from registry
rem ######################################
:GetRegEnv
rem ######################################
"%WinDir%\System32\Reg" QUERY "%~1" > "%TEMP%\_envget.tmp"
for /f "usebackq skip=2" %%A in ("%TEMP%\_envget.tmp") do (
    if /i not "%%~A"=="Path" (
        call :SetFromReg "%~1" "%%~A" "%%~A"
    )
)
exit /b

rem ######################################
:pip_upgrade_all
rem ######################################

pip freeze >"%TMP%\~pip1.txt"
for /F "tokens=*" %%a in ("%TMP%\~pip1.txt") do for /F "delims=^=^=" %%b in ("%%a") do echo %%b >> "%TMP%\~pip2.txt"
del "%TMP%\~pip1.txt"
pip install -U -r "%TMP%\~pip2.txt"
del "%TMP%\~pip2.txt"
echo Done.
exit /b

rem ######################################
:pip_transfer
rem ######################################

setlocal EnableDelayedExpansion
if not exist "%PYTHON_VERSION_DIR%\%1\" (
	echo [Error] Version %1 is not installed.
	exit /b
)
if not exist "%PYTHON_VERSION_DIR%\%2\" (
	set RESULT=
	echo Version %2 is not installed.
	set /p "RESULT=Do you want to install it now? [y/N] "
	if "!RESULT!" neq "y" (
		exit /b
	)
	powershell pyenv.ps1 install %2
	if not exist "%PYTHON_VERSION_DIR%\%2\" (
		echo [Error] Version %2 could not be installed.
		exit /b
	)
)

set PYTHONHOME_ORG=%PYTHONHOME%

set PYTHONHOME=%PYTHON_VERSION_DIR%\%1
call :refresh_env
pip freeze >"%TMP%\~pip.txt"

set PYTHONHOME=%PYTHON_VERSION_DIR%\%2
call :refresh_env
pip install -U -r "%TMP%\~pip.txt"

del "%TMP%\~pip.txt"
set PYTHONHOME=%PYTHONHOME_ORG%
call :refresh_env
echo Done.
exit /b
