MPV_IP="http://192.168.1.39:8080"

CURL_FLAGS="--compressed --insecure"

COOKIE="/home/pi/.cache/ELAN-login.cookie"

DEBUG=0

login() {
  #DATA_ROW='--data-raw name=Service&key=6075d4f0750c43d3f7311db1bdf4b2fda56693ec'
  DATA_ROW="--data-raw name=${LOGIN_NAME}&${KEY}"
  curl -s -c ${COOKIE} ${MPV_IP}/login \
    -H 'Connection: keep-alive' \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'X-Requested-With: XMLHttpRequest' \
    -H 'User-Agent: Mozilla/5.0 (X11; Linux armv7l) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36' \
    -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
    -H 'Origin: http://192.168.1.56' \
    -H 'Referer: http://192.168.1.56/' \
    -H 'Accept-Language: en-US,en;q=0.9' \
    ${CURL_FLAGS} ${DATA_ROW}
    #--data-raw 
    #'name=Service&key=6075d4f0750c43d3f7311db1bdf4b2fda56693ec'
    # [[ $DEBUG == 1 ]] && echo "DEBUG"
}

play() {
  curl "${MPV_IP}/api/play" \
    -X 'POST'   \
    -H 'Connection: keep-alive' \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'X-Requested-With: XMLHttpRequest' \
    -H 'User-Agent: Mozilla/5.0 (X11; Linux armv7l) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36' \
    -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
    -H 'Accept-Language: en-US,en;q=0.9' \
#    --data-raw '{"play",'true'}' \
#    ${CURL_FLAGS}
}

pause() {
  curl "${MPV_IP}/api/pause" \
    -X 'POST'   \
    -H 'Connection: keep-alive' \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    -H 'X-Requested-With: XMLHttpRequest' \
    -H 'User-Agent: Mozilla/5.0 (X11; Linux armv7l) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36' \
    -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
    -H 'Accept-Language: en-US,en;q=0.9' \
#    --data-raw '{"play",'true'}' \
#    ${CURL_FLAGS}
}

${1''}