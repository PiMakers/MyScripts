# PWM2.py
# Set RGB color
## www.python-exemplary.com/drucken.php?inhalt_mitte=raspi/en/leddimming.inc.php

#!/usr/bin/env python

import RPi.GPIO as GPIO
import time
import random

FLOOR_0 = 33    # GPIO 13
FLOOR_1 = 35    # GPIO 19
FLOOR_2 = 36    # GPIO 16
FLOOR_3 = 37    # GPIO 26
FLOOR_4 = 38    # GPIO 20
FLOOR_5 = 40    # GPIO 21
fPWM = 50  # Hz (not higher with software PWM)

def setup():
    global pwm0, pwm1, pwm2, pwm3, pwm4, pwm5
    GPIO.setmode(GPIO.BOARD)
    GPIO.setup(FLOOR_0, GPIO.OUT)
    GPIO.setup(FLOOR_1, GPIO.OUT)
    GPIO.setup(FLOOR_2, GPIO.OUT)
    GPIO.setup(FLOOR_3, GPIO.OUT)
    GPIO.setup(FLOOR_4, GPIO.OUT)
    GPIO.setup(FLOOR_5, GPIO.OUT)
    pwm0 = GPIO.PWM(FLOOR_0, fPWM)
    pwm1 = GPIO.PWM(FLOOR_1, fPWM)
    pwm2 = GPIO.PWM(FLOOR_2, fPWM)
    pwm3 = GPIO.PWM(FLOOR_3, fPWM)
    pwm4 = GPIO.PWM(FLOOR_4, fPWM)
    pwm5 = GPIO.PWM(FLOOR_5, fPWM)
    pwm0.start(0)
    pwm1.start(0)
    pwm2.start(0)
    pwm3.start(0)
    pwm4.start(0)
    pwm5.start(0)
    
def setLights(f0, f1, f2, f3, f4, f5):
    pwm0.ChangeDutyCycle(int(f0 / 255 * 100))
    pwm1.ChangeDutyCycle(int(f1 / 255 * 100))
    pwm2.ChangeDutyCycle(int(f2 / 255 * 100))
    pwm3.ChangeDutyCycle(int(f3 / 255 * 100))
    pwm4.ChangeDutyCycle(int(f4 / 255 * 100))
    pwm5.ChangeDutyCycle(int(f5 / 255 * 100))
    
setup()
while True:
    f0 = random.randint(0, 255)
    f1 = random.randint(0, 255)
    f2 = random.randint(0, 255)
    f3 = random.randint(0, 255)
    f4 = random.randint(0, 255)
    f5 = random.randint(0, 255)
    f4 = 200
    f5 = 200

    print (f0, f1, f2, f3, f4, f5)
    setLights(f0, f1, f2, f3, f4, f5)
    time.sleep(0.2)