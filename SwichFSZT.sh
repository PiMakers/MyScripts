#!/bin/bash

# fszt={1..8}

## MAIN:
## E2-Piócák=4; E2-Vizelet=5; -SERVER=7;-E9-BAL???=10;E3-latin=11; E8-MyHero=12; E4-Bolcso=13; -???=14; E7-Hadászat=15; E7-Animatik=16;
## E6-CloudsRL=17; E6-CloudsFL=18; E6-Clouds_RR=19; -???=20; E1-Heraldika (<- AP122 <- AP121 2)=ether23; E4-Mese=24
POEswitch1="25 0 0 4 5 0 0 0 0 0 11 12 13 0 15 16 17 18 19 0 0 0 25 24"
POEswitch1="25 0 0 4 0 0 0 0 0 0 11  0 13 0  0 16 17 18 19 0 0 0 23 24" #-5;
## FSZT:
POEswitch2="1 2 3 0 5 6 0 0 9 0 0 0 13 0 0 0 17 0 19 0 21 0 0 0"

## E7-Mikes=1; E2-Teremhang = 2; E8-Fire=5; E7/tenger=8:
POEswitch110="1 2 0 0 5 0 0 8"

##                  =1; E9-5.15b_MemoryTrees=3; E9-5.20ab_SK_Ruszin=4; E9-Szalagos=5; E9-5.13b_OnPaints=6; E9-ReBurial=7;E9-5.16b_KurucnotaTarogatos=8:
POEswitch111="1 0 3 4 5 6 7 8"

## E9-FundationFilm=1; E9-5.15b_MemoryTrees=3; E6_Animatik=4; E9-Szalagos=5; E9-5.13b_OnPaints=6; e9-5-2a-scary=7;E9-5.16b_KurucnotaTarogatos=8:
POEswitch112="1 0 3 4 5 6 7 8"

## E6-CloudsFR=2; E6_Animatik=4;
POEswitch113="0 2 0 4 0 0 0 0"

## E1-Heraldika
POEswitch121="0 2"

POEswitches="1 2 110 111 112 113 121"

fsz_hosts="f1-teremhang \
           f2-periodizacio \
           f3-windowtopast-left \
           f3-windowtopast-center \
           f3-windowtopast-right \
           f3-inventarium-a \
           f3-inventarium-b \
           f5-teremhang \
           f6-animatik \
           f6-teremhang"

emelet_hosts="e1-heraldika \
              e2-teremhang \
              e2-piocak \
              e2-vizelet \
              e3-latin \
              e4-bolcso \
              e4-mese \
              e6-cloudsfl \
              e6-cloudsfr \
              e6-cloudsrl \
              e6-cloudsrr \
              e6-animatik \
              e7-animatik \
              e7-hadaszat \
              e7-tenger \
              e7-mikes \
              e8-fire \
              e8-myhero \
              e9-fundationfilm \
              e9-5-2a-scary \
              e9-5-3b-szobrok \
              e9-5-5b-tenkeskapitanya \
              e9-5-6a-marses \
              e9-5-6b-konnyuzene \
              e9-reburial \
              e9-5-13b-onpaints \
              e9-5-15b-memorytrees \
              e9-5-16a-radio \
              e9-5-16b-kurucnotatarogato \
              e9-5-20abszlovakruszin \
              e9-Szalagos"

hosts="${fsz_hosts} ${emelet_hosts}"

switchOn(){
#    POEswitches="1 2 110 111 112 113 121"
    for POEswitch in ${POEswitches}
        do
            /home/pi/MyScripts/MikroTik.sh MON ${POEswitch}
            local i=1
            local tmp="POEswitch${POEswitch}"
            ports="${!tmp}"
            echo "****************PORTS = $ports"
            for port in ${ports}
                do
                    local SW=ON
                    # [[ ${port} == $i ]] || SW=QOFF
                    # echo "Switching ${SW} POEswitch ${POEswitch} port: ${i}"
                    [[ ${port} == $i ]] && echo "Switching ${SW} POEswitch ${POEswitch} port: ${i}" && /home/pi/MyScripts/MikroTik.sh ${SW} ${POEswitch} ${i} &
                    i=$(($i+1))
                done
            /home/pi/MyScripts/MikroTik.sh MON ${POEswitch}
        done
}

switchOff(){
    for host in ${hosts}
        do
            echo "Switching OFF: ${host}"
            ssh root@${host}.local 'shutdown now' || continue
            #ssh root@${host}.local 'echo "`hostname`: OK"'
        done
}

switch() {
    for host in ${hosts}
        do
            case ${1^^} in
              on|ON)
                    echo "TEST ON: ${host}"
                    ;;
            off|OFF)
                    echo "TEST OFF: ${host}"
                    ssh root@${host}.local 'shutdown now' & #|| continue
                    ;;
           
                QOFF)
#                        POEswitches="1 2 110 111 112 113 121"
                        for POEswitch in ${POEswitches}
                            do
                                /home/pi/MyScripts/MikroTik.sh MON ${POEswitch}
                                local i=1
                                local tmp="POEswitch${POEswitch}"
                                ports="${!tmp}"
                                echo "****************PORTS = $ports"
                                for port in ${ports}
                                    do
                                        local SW=QOFF
                                        [[ ${port} == [$i,0] ]] || SW=QOFF
                                        echo "Switching ${SW} POEswitch ${POEswitch} port: ${i}"
                                        /home/pi/MyScripts/MikroTik.sh ${SW} ${POEswitch} ${i} &
                                        i=$(($i+1))
                                    done
                                /home/pi/MyScripts/MikroTik.sh MON ${POEswitch} &
                            done
                        return
                        ;;

       reboot|REBOOT)
                    echo "TEST REBOOT: ${host}"
                    (ssh root@${host/\#/}.local 'reboot' & )||  ( ((j++)) && echo "--${host/\#/}: FAILED !" )
                    ;;        
                  *)
                    # echo "TEST $1: ${host/\#/}"
                    ( ssh root@${host/\#/}.local 'echo "--`hostname`: OK"' && ((i++)) ) || ( ((j++)) && echo "--${host/\#/}: FAILED !$j" )
                    ;;
            esac
        done
        echo "::OK $i     FAILED: $j"
}


fsz="{1..24}"
switchQOff(){
    local POEswitch=110
    for port in {1..8} #${fsz}
        do
            echo "Switching qOFF POEswitch ${POEswitch} port: ${port}"
            /home/pi/MyScripts/MikroTik.sh QOFF ${POEswitch} ${port} &
        done
}

switchMon(){
    for POEswitch in ${POEswitches}
        do
            echo "Monitoring POEswitch ${POEswitch}:"
            /home/pi/MyScripts/MikroTik.sh MON ${POEswitch}
            echo "=========================================="
        done
}



case "$1" in
    ON|on) switchOn
            ;;

    OFF|off)
            switchOff
            ;;
    QOFF|qoff)
            switchQOff
            ;;
    MON|mon)
            switchMon
            ;;
    TEST|test)
            switch $2
            ;;
        *)
            switchOn
    esac

# cat ~/.ssh/id_rsa.pub |ssh root@${INSTALL_NAME}.local 'cat > .ssh/authorized_keys'
# ssh root@${INSTALL_NAME}.local 'echo "Teszt: OK!"'
