# F6-Animatik, E6-Animatik, E7-Animatik 

import sys
sys.path.append('/storage/.kodi/addons/virtual.rpi-tools/lib')
import RPi.GPIO as GPIO
import time
import xbmc

button = 14
red    = 15
green  = 18
blue   = 23

def setup():
	xbmc.log( msg='This is a test string.', level=xbmc.LOGDEBUG)
       # GPIO.BCM = GPIO number GPIO.BOARD = PIN number
       GPIO.setmode(GPIO.BCM)
       GPIO.setup(button, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
       GPIO.setup(red, GPIO.OUT)
       GPIO.setup(green, GPIO.OUT)
       GPIO.setup(blue, GPIO.OUT)

def loop():
        counter = 0
        while True:
              button_state = GPIO.input(button)
              if  button_state == False:
               if counter == 0:
                  GPIO.output(red, True)
                  GPIO.output(green, False)
                  GPIO.output(blue, False)
               elif counter == 1:
                  GPIO.output(red, False)
                  GPIO.output(green, True)
                  GPIO.output(blue, False)
               elif counter == 2:
                  GPIO.output(red, False)
                  GPIO.output(green, False)
                  GPIO.output(blue, True)

               xbmc.log(msg='Button Pressed...', level=xbmc.LOGINFO)
               xbmc.executebuiltin( "PlayerControl(Next)" )
               counter += 1
               counter = counter%3
               while GPIO.input(button) == False:
                    time.sleep(0.2)

def endprogram():
       GPIO.output(red, False)
       GPIO.output(green, False)
       GPIO.output(blue, False)
       GPIO.cleanup()


if __name__ == '__main__':

          setup()
          try:
                 loop()

          except KeyboardInterrupt:
        xbmc.log( msg='keyboard interrupt detected', level=xbmc.LOGERROR)
         print ('keyboard interrupt detected')
                 endprogram()
