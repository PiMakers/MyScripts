::# https://forum.snapcraft.io/t/running-snaps-on-wsl2-insiders-only-for-now/13033
::# https://gist.github.com/stowler/9921780 # VcXserver cmd-s
::# remove "UNC paths are not supported" message: 2>nul or
::# HKEY_CURRENT_USER\Software\Microsoft\Command Processor  add the value DisableUNCCheck REG_DWORD and set the value to 0 x 1 (Hex).
:: C:\WINDOWS\System32\wsl.exe -d Ubuntu-20.04 sh -c '"$VSCODE_WSL_EXT_LOCATION/scripts/wslServer.sh" a5d1cc28bb5da32ec67e86cc50f84c67cc690321 stable .vscode-server 0  ' in c:\Users\highd\.vscode\extensions\ms-vscode-remote.remote-wsl-0.44.3
cls
@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

set DISTRO=Ubuntu-20.04
wsl.exe -d %DISTRO% -e printenv WSL_DISTRO_NAME > nul
if errorlevel 0 ( GOTO hopp ) else ( GOTO kopp )

:kopp
    echo Wsl2 %DISTRO% needs reinstall
    wsl.exe --unregister %DISTRO%
    set APPNAME=I:\wsl\appx\%DISTRO%.appx
    if not exist %APPNAME% ( curl.exe -L -o %APPNAME% https://aka.ms/wslubuntu2004 )
    ::@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "Add-AppxPackage %APPNAME%" && ECHO HURRAH!
GOTO install

:install
echo not fully implemented yet!  check script if error!
%LOCALAPPDATA%\Microsoft\WindowsApps\ubuntu2004.exe install
wsl.exe --set-default %DISTRO%
echo insall succsess!

:hopp
echo hoppp
::type N:\myGitHub\MyScripts\WSL\myWSL | wsl.exe -d %DISTRO%
::net use w: \\wsl$\Ubuntu-20.0
net use /persistent:yes w: \\wsl$\Ubuntu-20.04
copy N:\myGitHub\MyScripts\WSL\myWSL w:\home\pimaker
::copy N:\myGitHub\MyScripts\WSL\SnapsOnWsl2.sh w:\tmp
bash -c "source ~/myWSL"
::bash -c "source /tmp/SnapsOnWsl2.sh"
GOTO end

:end
ENDLOCAL
::pause
exit /b