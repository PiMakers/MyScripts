import sys
sys.path.append('/usr/share/kodi/addons/virtual.rpi-tools/lib')
import RPi.GPIO as GPIO
# import xbmc, xbmcgui
import time

btn1 = 14
btn2 = 15
btn3 = 23
btn4 = 24

def signal_handler(sig, frame):
    GPIO.cleanup()
    sys.exit(0)

def btn1_released_callback(channel):
    # xbmc.log( msg='BTN1 PRESSED', level=xbmc.LOGINFO)
    print('BTN1 PRESSED' + str(channel))

def btn2_released_callback(channel):
  # xbmc.log( msg='BTN2 PRESSED', level=xbmc.LOGINFO)
    print('BTN2 PRESSED' + str(channel))
def btn3_released_callback(channel):
  # xbmc.log( msg='BTN3 PRESSED', level=xbmc.LOGINFO)
    print('BTN3 PRESSED' + str(channel))
def btn4_released_callback(channel):
  # xbmc.log( msg='BTN4 PRESSED', level=xbmc.LOGINFO)    
    print('BTN4 PRESSED' + str(channel))

if __name__ == '__main__':
  # xbmc.log( msg='This is a test string.', level=xbmc.LOGINFO)
    # GPIO.BCM = GPIO number GPIO.BOARD = PIN number
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(btn1, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    GPIO.setup(btn2, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    GPIO.setup(btn3, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    GPIO.setup(btn4, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

    GPIO.add_event_detect(btn1, GPIO.RISING, callback=btn1_released_callback, bouncetime=500)
    GPIO.add_event_detect(btn2, GPIO.RISING, callback=btn2_released_callback, bouncetime=500)
    GPIO.add_event_detect(btn3, GPIO.RISING, callback=btn3_released_callback, bouncetime=500)
    GPIO.add_event_detect(btn4, GPIO.RISING, callback=btn4_released_callback, bouncetime=500)

    # signal.signal(signal.SIGINT, signal_handler)

    while True:
      # xbmc.sleep(1)
      time.sleep(1)

