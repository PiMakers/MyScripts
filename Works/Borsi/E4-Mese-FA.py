import sys
sys.path.append('/storage/.kodi/addons/virtual.rpi-tools/lib')

import xbmc
import RPi.GPIO as GPIO

PIN_TRIGGER = 24
PIN_ECHO = 23

class ProxyPlayer(xbmc.Player):
  def __init__(self):
    self.started = False
    xbmc.executebuiltin('PlayerControl(RepeatOff)')
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
    GPIO.setup(PIN_ECHO, GPIO.IN)

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

    if distance < 2000:
      self.onProxyTrigger()

  def onProxyTrigger(self):
    if not self.started:
      self.started = True
      self.play('/storage/music/mese.mp4')

  def onPlayBackEnded(self):
    self.started = False

if __name__ == '__main__':
  ProxyPlayer()