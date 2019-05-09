## https://stackoverflow.com/questions/17510688/single-script-to-run-in-both-windows-batch-and-linux-bash

## https://unix.stackexchange.com/questions/259630/trace-a-binary-stream-from-a-device-file
# Trace a binary stream from a device file
# First the tty is set to raw mode.
stty -F /dev/ttyAPP2 raw
# then
cat /dev/ttyAPP2