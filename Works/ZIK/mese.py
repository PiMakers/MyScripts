"""
Ez a script 2 méternél közelebbi ember esetén lejátszik egy fájlt.

Beállítandó változók:

AUDIO_PATH = lejátszandó fájl helye
"""

AUDIO_PATH = '/storage/music/E4-Mese.wav'

PIN_TRIGGER = 24
PIN_ECHO = 23

import sys
sys.path.append('/storage/.kodi/addons/virtual.rpi-tools/lib')

import xbmc
import time
import RPi.GPIO as GPIO

class ProxyPlayer(xbmc.Player):
  def __init__(self):
    self.started = False
    xbmc.executebuiltin('PlayerControl(RepeatAll)')
    # xbmc.executebuiltin('SetVolume(70)')
    self.initGPIO()

    monitor = xbmc.Monitor()
    while not monitor.abortRequested():
      if monitor.waitForAbort(1):
        GPIO.cleanup()
      else:
        self.measure()

  def initGPIO(self):
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(PIN_TRIGGER, GPIO.OUT)
    GPIO.setup(PIN_ECHO, GPIO.IN, pull_up_down = GPIO.PUD_DOWN)

  def measure(self):
    GPIO.output(PIN_TRIGGER, GPIO.HIGH)
    time.sleep(0.00001)
    GPIO.output(PIN_TRIGGER, GPIO.LOW)

    while GPIO.input(PIN_ECHO) == 0:
      pulse_start_time = time.time()
    while GPIO.input(PIN_ECHO) == 1:
      pulse_end_time = time.time()

    pulse_duration = pulse_end_time - pulse_start_time
    distance = round(pulse_duration * 17150, 2)

    if distance < 200:
      xbmc.log('Triggered, distance = ' + str(distance), level = xbmc.LOGWARNING)
      self.onProxyTrigger()

  def onProxyTrigger(self):
    if not self.started:
      self.started = True
      xbmc.executebuiltin('PlayMedia(' + AUDIO_PATH + ')')

  def onPlayBackEnded(self):
    self.started = False

if __name__ == '__main__':
  ProxyPlayer()
