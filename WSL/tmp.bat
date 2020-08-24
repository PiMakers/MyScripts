@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

GOTO KILL_UNWANTED_APPS
rem haho
echo echpo
exit /B

:KILL_UNWANTED_APPS
:: Microsoft.Photos.exe, MicrosoftEdge.exe, MicrosoftEdgeSH.exe, MicrosoftEdgeCP.exe
taskkill /f /IM Microsoft*
::Cortana ?
taskkill /f /IM Adobe*
GOTO end

:LOOPSTART
echo %DATE:~0% %TIME:~0,8% >> Pingtest.log

SET scriptCount=1
FOR /F "tokens=* USEBACKQ" %%F IN (`ping google.com -n 1`) DO (
  SET commandLineStr!scriptCount!=%%F
  SET /a scriptCount=!scriptCount!+1
)
@ECHO %commandLineStr1% >> PingTest.log
@ECHO %commandLineStr2% >> PingTest.log
ENDLOCAL

timeout 5 > nul

GOTO LOOPSTART

:end
ENDLOCAL
exit /B