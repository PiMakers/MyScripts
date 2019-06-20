# https://ryanstutorials.net/bash-scripting-tutorial/

#!/bin/bash
# A simple menu system
names='Kyle Cartman Stan Quit'
echo PS3="$PS3"
PS3='Select character: '
select name in $names
do
if [ $name == 'Quit' ]
then
break
fi
#switch $name
case in 
	Kyle)
		echo "WWWWWWWWWWWW";;
	*)
		echo "$1";;
esac
echo Hello $name
done
echo Bye
