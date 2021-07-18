




import signal
import sys
sys.path.append('/storage/.kodi/addons/virtual.rpi-tools/lib')
import time
import xbmc
import RPi.GPIO as GPIO


BUTTON_GPIO = 14
LED_GPIO = 18

should_blink = True

def signal_handler(sig, frame):
    GPIO.cleanup()
    sys.exit(0)

def button_released_callback(channel):
    global should_blink
    should_blink = not should_blink

if __name__ == '__main__':
    GPIO.setmode(GPIO.BCM)

    GPIO.setup(BUTTON_GPIO, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    GPIO.setup(LED_GPIO, GPIO.OUT)

    GPIO.add_event_detect(BUTTON_GPIO, GPIO.BOTH,
            callback=button_released_callback, bouncetime=200)

    signal.signal(signal.SIGINT, signal_handler)

    while True:
        if should_blink:
            GPIO.output(LED_GPIO, GPIO.HIGH) 
        time.sleep(0.5)
        if should_blink:
            GPIO.output(LED_GPIO, GPIO.LOW)  
        time.sleep(0.5)
