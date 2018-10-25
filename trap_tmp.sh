#!/bin/bash

b="true"

sigquit()
{
   echo "signal QUIT received"
}

sigint()
{
   echo "signal INT received, script ending"
   b="false"
#   ps -ax | grep bash
}

trap 'sigquit' QUIT
trap 'sigint'  INT
# trap ':'       HUP      # ignore the specified signals

echo "test script started. My PID is $$"
while $b ; do
	echo "sleeping...."  
	sleep 30
done
exit 0
