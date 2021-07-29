import sys
sys.path.append('/storage/.kodi/addons/virtual.rpi-tools/lib')

import xbmc
import xbmcgui
import RPi.GPIO as GPIO

class ButtonPlayer(xbmc.Player):  
  def __init__(self):
    self.keyPresses = 0
    self.modCurrent = 0

    self.button = 14
    #self.button = 21
    self.red    = 23
    self.green  = 18
    self.blue   = 15

    self.started = False
    self.ended = False

    # set pin order here, according to playlist.m3u
    self.pinOrder = [self.green, self.blue, self.red]

    xbmc.executebuiltin('PlayMedia(/storage/.kodi/userdata/playlists/video/playlist.m3u)')
    xbmc.executebuiltin('PlayerControl(RepeatAll)')
    
    self.initGPIO()
    self.initVideo()
    
    monitor = xbmc.Monitor()
    while not monitor.abortRequested():
      if monitor.waitForAbort(1):
        GPIO.cleanup()
      else:
        self.playVideo()
    
  def initGPIO(self):
    GPIO.setwarnings(False)
    GPIO.cleanup([self.button, self.red, self.green, self.blue])
    
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(self.button, GPIO.IN, pull_up_down = GPIO.PUD_DOWN)
    GPIO.add_event_detect(self.button, GPIO.RISING, bouncetime = 300, callback = self.onButtonPressed)
    
    GPIO.setup(self.red, GPIO.OUT)
    GPIO.setup(self.green, GPIO.OUT)
    GPIO.setup(self.blue, GPIO.OUT)
    
    self.setLedColor()
    
  def initVideo(self):
    self.started = False
    while not self.isPlaying():
      xbmc.sleep(100)
    xbmc.executebuiltin('ActivateWindow(VideoFullScreen.xml)')
    xbmc.sleep(1700)
    if not self.started:
      xbmc.executebuiltin('PlayerControl(Play)')
      self.seekTime(1.7)

  def onButtonPressed(self, channel):
    # xbmcgui.Dialog().notification('PlayerEvent', 'Button pressed: ' + str(channel))
    self.ended = False
    if self.started:
      self.keyPresses += 1
      self.setLedColor()
    else:
      self.started = True
      xbmc.executebuiltin('PlayerControl(Play)')

  def playVideo(self):
    mod = self.keyPresses % len(self.pinOrder)
    if self.modCurrent != mod and not self.ended:
      self.started = True
      xbmc.executebuiltin('PlayList.PlayOffset(' + str(mod - self.modCurrent) + ')')
    self.modCurrent = mod
    
  def onPlayBackEnded(self):
    self.ended = True
    self.keyPresses += 1
    self.setLedColor()
    self.initVideo()
    
  def setLedColor(self):
    for i in range(len(self.pinOrder)):
      GPIO.output(self.pinOrder[i], self.pinOrder[self.keyPresses % len(self.pinOrder)] == self.pinOrder[i])

if __name__ == '__main__':
  ButtonPlayer()