# PWM2.py
# Set RGB color

import sys
sys.path.append('/storage/.kodi/addons/virtual.rpi-tools/lib')
# sys.path.append('/storage/.kodi/mySripts')

import RPi.GPIO as GPIO
import time
# import random
import xbmc

button  = 14
P_RED   = 15     # adapt to your wiring
P_GREEN = 18   # ditto
P_BLUE  = 23    # ditto
fPWM = 50      # Hz (not higher with software PWM)

def setup():
    global pwmR, pwmG, pwmB
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(button, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    GPIO.setup(P_RED, GPIO.OUT)
    GPIO.setup(P_GREEN, GPIO.OUT)
    GPIO.setup(P_BLUE, GPIO.OUT)
    pwmR = GPIO.PWM(P_RED, fPWM)
    pwmG = GPIO.PWM(P_GREEN, fPWM)
    pwmB = GPIO.PWM(P_BLUE, fPWM)
    pwmR.start(0)
    pwmG.start(0)
    pwmB.start(0)
 
def setColor(r, g, b):
    pwmR.ChangeDutyCycle(int(r / 255 * 100))
    pwmG.ChangeDutyCycle(int(g / 255 * 100))
    pwmB.ChangeDutyCycle(int(b / 255 * 100))
def setRed():
    pwmR.ChangeDutyCycle(100)
    pwmG.ChangeDutyCycle(0)
    pwmB.ChangeDutyCycle(0)
def setBlue():
    setColor(0,0,255)

print ("starting")
setup()

try:
    while True:
        button_state = GPIO.input(button)
        if  button_state == False:
            #print (r, g, b)
            setRed()
            print('Button Pressed...')
            xbmc.executebuiltin( "PlayerControl(Play)" )
            xbmc.executebuiltin( "PlayerControl(Next)" )
            while GPIO.input(button) == False:
                    setBlue()
                    time.sleep(0.2)
        else:
            setColor(0,100,0)
            time.sleep(1.0)
            setBlue()
            setBlue()

except KeyboardInterrupt:
    print ("CleaningUp...")
    pwmR.stop()
    pwmG.stop()
    pwmB.stop()
    GPIO.cleanup()
