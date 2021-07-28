import sys
sys.path.append('/storage/.kodi/addons/virtual.rpi-tools/lib')

import xbmc
import xbmcgui
import RPi.GPIO as GPIO
import signal

class ButtonPlayer(xbmc.Player):  
  def __init__(self):
    # total press count
    self.keyPresses = 0
    
    # pin settings
    self.button = 8
    self.red = 16
    self.green = 12
    self.blue = 10

    self.started = False
    self.stopping = False
    
    # set pin order here, according to playlist.m3u
    self.pinOrder = [self.green, self.blue, self.red]

    xbmc.executebuiltin('PlayMedia(/storage/.kodi/userdata/playlists/video/playlist.m3u)')
    xbmc.executebuiltin('PlayerControl(RepeatAll)')
    
    self.initGPIO()
    self.initVideo()
    
    monitor = xbmc.Monitor()
    while not monitor.abortRequested():
      if GPIO.event_detected(self.button):
        self.onButtonPressed()
      if monitor.waitForAbort(1) or self.stopping:
        break

    self.cleanup()

  def __del__(self):
    self.cleanup()
    
  def initGPIO(self):
    try:
      GPIO.cleanup([self.button, self.red, self.green, self.blue])
    except:
      pass
    
    GPIO.setmode(GPIO.BOARD)
    GPIO.setup(self.button, GPIO.IN, pull_up_down = GPIO.PUD_DOWN)
    GPIO.add_event_detect(self.button, GPIO.BOTH, bouncetime = 2000)
    
    GPIO.setup(self.red, GPIO.OUT)
    GPIO.setup(self.green, GPIO.OUT)
    GPIO.setup(self.blue, GPIO.OUT)
    
    self.setLedColor()
    
  def initVideo(self):
    self.started = False
    xbmc.sleep(2000)
    while not self.isPlaying():
      xbmc.sleep(100)
    xbmc.executebuiltin('ActivateWindow(VideoFullScreen.xml)')
    if not self.started:
      xbmc.executebuiltin('PlayerControl(Play)')  
      self.seekTime(1.7)

  def onButtonPressed(self):
    # xbmcgui.Dialog().notification('PlayerEvent', 'Button pressed')
    if self.started:
      xbmc.executebuiltin('PlayerControl(next)')
      self.keyPresses += 1
      self.setLedColor()
    else:
      self.started = True
      xbmc.executebuiltin('PlayerControl(Play)')
    
  def onPlayBackEnded(self):
    # xbmcgui.Dialog().notification('PlayerEvent', 'Playback ended')
    self.keyPresses += 1
    self.setLedColor()
    self.initVideo()
    
  def setLedColor(self):
    for i in range(len(self.pinOrder)):
      GPIO.output(self.pinOrder[i], self.pinOrder[self.keyPresses % len(self.pinOrder)] == self.pinOrder[i])

  def shutdown(self):
    self.stopping = True

  def cleanup(self):
    self.stopping = True
    GPIO.remove_event_detect(self.button)
    GPIO.cleanup([button, red, green, blue])
        

if __name__ == '__main__':
  xbmc.sleep(5000)
  bp = ButtonPlayer()
  signal.signal(signal.SIGTERM, bp.shutdown)