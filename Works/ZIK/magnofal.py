# by PiMaker (+36 30 944 6153) to ZIK 2023 

import sys
sys.path.append('/usr/share/kodi/addons/virtual.rpi-tools/lib')

import RPi.GPIO as GPIO
import time
import xbmc, xbmcgui

class ButtonPlayer(xbmc.Player):
  def __init__( self, *args ):
    pass

  def run(self):
    self.count = 0
    self.Relay = [ 25, 24, 6, 27, 23, 4, 14, 15]  # Tartalék, 26,27]
    self.magno1 = (1, 0, 0, 0, 0, 0, 0, 0)
    self.magno2 = (0, 1, 0, 0, 0, 1, 0, 0)
    self.magno3 = (0, 0, 1, 0, 0, 0, 1, 0)
    self.magno4 = (0, 0, 0, 1, 0, 0, 0, 0)
    self.magno5 = (0, 0, 0, 0, 1, 0, 0, 1)
    self.magno=[self.magno1, self.magno2, self.magno3, self.magno4, self.magno5]

    self.initGPIO()
    self.switchGPIO()
    self.initVideo()

    monitor = xbmc.Monitor()

    while not monitor.abortRequested():
      monitor.waitForAbort(1)
    
    GPIO.cleanup()

  def initGPIO(self):
    GPIO.setmode(GPIO.BCM)
    GPIO.setwarnings(False)
    GPIO.setup(self.Relay, GPIO.OUT)

  def switchGPIO(self): 
    status =""
    for i in range(len(self.Relay)):
      status += str(self.Relay[i]) + ' -> ' + str(self.magno[self.count][i]) + '; '
      GPIO.output(self.Relay[i], self.magno[self.count][i])
    xbmc.log(msg='::: SWITCHING GPIOport:' + status, level = xbmc.LOGINFO)
    self.GPIOstatus()

  def GPIOstatus(self):
    status = ""
    for i in range(len(self.Relay)):
      status +=  str(GPIO.input(self.Relay[i])) + ' ;' 
    xbmc.log(msg='::: GPIO STATUS: ' + status , level = xbmc.LOGINFO)
  
  def initVideo(self):
    while not self.isPlayingVideo():
      xbmc.sleep(100)

  def onPlayBackStarted(self):
    xbmc.log(msg='::: onPlayBackStarted ' + str(self.count + 1), level = xbmc.LOGINFO)
    xbmcgui.Dialog().notification('PlayerEvent', 'started')
    self.initVideo()

  def onPlayBackEnded(self):
    xbmc.log(msg='::: onPlayBackEnded ' + str(self.count + 1), level = xbmc.LOGINFO)
    xbmcgui.Dialog().notification('PlayerEvent', str(self.count + 1) + 'ended')
    self.count += 1
    self.count %= 5
    self.switchGPIO()

if __name__ == '__main__':
  xbmc.log(msg='::: This is a test string.Started', level=xbmc.LOGINFO)
  xbmc.executebuiltin( "SetVolume(100)" )
  p = ButtonPlayer()
  p.play('/storage/.kodi/userdata/playlists/video/zik.m3u')
  xbmc.executebuiltin('PlayerControl(RepeatAll)')
  p.run()
