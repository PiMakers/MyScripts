# https://ryanstutorials.net/bash-scripting-tutorial/

#!/bin/bash
# A simple menu system
select_mode() {
    PS3='Please enter your choice: '
    options=( "Install" "Uninstall" "Quit" )
    # options+=( "More_Choises1" "More_Choises2" ... )
    # unset options[0]
    # options[2]="pocok"
    # arr=( "${arr[@]:0:2}" "new_element" "${arr[@]:2}" )
    select opt in "${options[@]}"
    do
        case $opt in
            "Install")
                echo "Installing $PROGNAME ..."
                INSTALL=1
                break 
                ;;
            "Uninstall")
                echo "Uninstalling $PROGNAME ..."
                INSTALL=0
                break 
                ;;
            "Quit")
                break
                ;;
            *) echo "invalid option $REPLY";;
        esac
    done
}

