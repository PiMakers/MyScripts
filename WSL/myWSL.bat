:# https://forum.snapcraft.io/t/running-snaps-on-wsl2-insiders-only-for-now/13033
:# https://gist.github.com/stowler/9921780 # VcXserver cmd-s
:# remove "UNC paths are not supported" message: 2>nul or
:# HKEY_CURRENT_USER\Software\Microsoft\Command Processor  add the value DisableUNCCheck REG_DWORD and set the value to 0 x 1 (Hex).
:# C:\WINDOWS\System32\wsl.exe -d Ubuntu-20.04 sh -c '"$VSCODE_WSL_EXT_LOCATION/scripts/wslServer.sh" a5d1cc28bb5da32ec67e86cc50f84c67cc690321 stable .vscode-server 0  ' in c:\Users\highd\.vscode\extensions\ms-vscode-remote.remote-wsl-0.44.3

:: export X=World
:: export WSLENV=X/w
:: cmd.exe /c 'echo Hello, %X%!'
cls
@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
:: kali: https://aka.ms/wsl-kali-linux-new
:: ubuntu: https://aka.ms/wsl-ubuntu-1804
:: https://aka.ms/wslubuntu2004
set DISTRO=Ubuntu-20.04
::set DISTRO=kali-linux

echo %APPNAME% %MS_STORE_LINK%/%DL_LINK%
mkdir %TMP%\%DISTRO%
wsl.exe -d %DISTRO% -e printenv USER >%TMP%\%DISTRO%\user.txt
if errorlevel 0 ( GOTO installed ) else ( GOTO kopp )

:kopp
    set MS_STORE_LINK=https://aka.ms
    if "%DISTRO%" == "Ubuntu-20.04" (set DL_LINK=wslubuntu2004 && set APP_EXE=ubuntu2004.exe) else (
    if "%DISTRO%" == "kali-linux" (set DL_LINK=wsl-kali-linux-new && set APP_EXE=kali.exe) else echo DISTRO NOT SUPPORTED
    )
    echo Wsl2 %DISTRO% needs reinstall
    wsl.exe --unregister %DISTRO%
    set APPNAME=I:\wsl\appx\%DISTRO%.appx
    if not exist %APPNAME% ( curl.exe -L -o %APPNAME% %MS_STORE_LINK%/%DL_LINK% )
    ::@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "Add-AppxPackage %APPNAME%" && ECHO HURRAH!
    GOTO install

:install
echo not fully implemented yet!  check script if error!
%LOCALAPPDATA%\Microsoft\WindowsApps\%APP_EXE% install
wsl.exe -d %DISTRO% -e printenv USER >%TMP%\%DISTRO%\user.txt
wsl.exe --set-default %DISTRO%
bash -c "echo $USER">%TMP%\%DISTRO%\user.txt
echo insall succsess!

:installed
    echo %DISTRO% installed
:while
    dir w:>nul
    ::echo %errorlevel%
    if not %errorlevel% == 0 ( net use /persistent:yes w: \\wsl$\%DISTRO% )
    set /p USER=<%TMP%\%DISTRO%\user.txt
    copy /Y N:\myGitHub\MyScripts\WSL\myWSL w:\home\%USER%
    bash -c "source ~/myWSL && sudo rm ~/myWSL"
    copy /Y N:\myGitHub\MyScripts\WSL\SnapsOnWsl2.sh w:\home\%USER%
    bash -c "source ~/SnapsOnWsl2.sh && sudo rm ~/SnapsOnWsl2.sh"
 
:end
    :#pause
    rem cleanup
    rmdir /S /Q %TMP%\%DISTRO%
    wsl.exe -t %DISTRO%
    wsl.exe -d %DISTRO% -e echo myWSL.bat finished!
    ENDLOCAL
    exit /b