@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
:: kali: https://aka.ms/wsl-kali-linux-new
:: ubuntu: https://aka.ms/wsl-ubuntu-1804
:: wslubuntu2004
set DISTRO=Ubuntu-20.04
::set DISTRO=kali-linux
set STORE_LINK=https://aka.ms
if "%DISTRO%" == "Ubuntu-20.04" (set DL_LINK=wslubuntu2004 && set APP_EXE=ubuntu2004.exe) else (
if "%DISTRO%" == "kali-linux" (set DL_LINK=wsl-kali-linux-new && set APP_EXE=kali.exe) else echo DISTRO NOT SUPPORTED
)
echo DL_LINK=%APPNAME% %STORE_LINK%/%DL_LINK% APP_EXE=%APP_EXE%
wsl.exe -d %DISTRO% -e printenv WSL_DISTRO_NAME > nul
if errorlevel 0 ( GOTO hopp ) else ( GOTO kopp )

:hopp
    echo %DISTRO% works. OK.
    GOTO start

:kopp
    echo %DISTRO% not works!!!!!
    echo Wsl2 %DISTRO% needs reinstall
    wsl.exe --unregister %DISTRO% >null

    set APPNAME=I:\wsl\appx\%DISTRO%.appx
    if not exist %APPNAME% ( curl.exe -L -o %APPNAME% %STORE_LINK%/%DL_LINK% )
    GOTO install

:install
echo not fully implemented yet!  check script if error!
if exist %LOCALAPPDATA%\Microsoft\WindowsApps\%APP_EXE% ( %LOCALAPPDATA%\Microsoft\WindowsApps\%APP_EXE% install )
wsl.exe --set-default %DISTRO%
echo insall succsess!

:start
%LOCALAPPDATA%\Microsoft\WindowsApps\%APP_EXE%
GOTO end

:end
exit /B