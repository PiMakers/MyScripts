# https://roboticsbackend.com/raspberry-pi-gpio-interrupts-tutorial/
# RPi.GPIO interrupts application example #2


"""#!/usr/bin/env python3"""

import signal
import sys
sys.path.append('/storage/.kodi/addons/virtual.rpi-tools/lib')

import xbmc
import RPi.GPIO as GPIO

BUTTON_GPIO = 14
LED_GPIO = 18

last_LED_state = True

xbmc.log(msg='This is a test string!!!!!!!!!!!!!!!!!!!!!!.', level=xbmc.LOGINFO)

def signal_handler(sig, frame):
    GPIO.cleanup()
    sys.exit(0)

def button_pressed_callback(channel):
    global last_LED_state
    GPIO.output(LED_GPIO, not last_LED_state)
    last_LED_state = not last_LED_state
    xbmc.executebuiltin( "PlayerControl(Play)" )
    xbmc.log(msg='Button Pressed...', level=xbmc.LOGINFO)

if __name__ == '__main__':
    xbmc.log(msg='This is a test string.Started', level=xbmc.LOGINFO)
    GPIO.setmode(GPIO.BCM)

    GPIO.setup(BUTTON_GPIO, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    GPIO.setup(LED_GPIO, GPIO.OUT)

    GPIO.add_event_detect(BUTTON_GPIO, GPIO.BOTH,
            callback=button_pressed_callback, bouncetime=200)

#    signal.signal(signal.SIGINT, signal_handler)
#    signal.pause()
