## https://stackoverflow.com/questions/17510688/single-script-to-run-in-both-windows-batch-and-linux-bash
:<<BATCH
    @echo off
    echo %PATH%
    exit /b
BATCH

echo $PATH
return