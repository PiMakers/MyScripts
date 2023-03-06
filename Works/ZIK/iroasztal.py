import sys
sys.path.append('/usr/share/kodi/addons/virtual.rpi-tools/lib')
import RPi.GPIO as GPIO
import xbmc
import time

DEBUG = True
SENSOR_PIN = 21
PAUSED = False

def setUpGPIO():
  GPIO.setmode(GPIO.BCM)
  GPIO.setup(SENSOR_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
  xbmc.log(msg='::: INITIALING PIR SENSOR', level=xbmc.LOGINFO)
  while SENSOR_PIN == 1:
    xbmc.sleep(100)
  xbmc.log(msg='::: PIR SENSOR READY', level=xbmc.LOGINFO)
  GPIO.add_event_detect(SENSOR_PIN , GPIO.RISING, callback=my_callback)

class PIMplayer(xbmc.Player):
  global PAUSED
  def __init__( self, *args ):
    pass

  def onPlayBackPaused(self):
    self.PAUSED = True
    if DEBUG:
       xbmc.log(msg='::: PLAYBACK PAUSED', level=xbmc.LOGINFO)

  def onPlayBackEnded(self):
    if DEBUG:
       xbmc.log(msg='::: PLAYBACK ENDED', level=xbmc.LOGINFO)

  def onPlayBackStarted(self):
    # self.pause()
    # xbmc.executebuiltin(PlayerControl(Pause))
    if DEBUG:
       xbmc.log(msg='::: PLAYBACK STARTED', level=xbmc.LOGINFO)

  def onAVStarted(self):
    xbmc.log(msg='::: onAVStarted', level = xbmc.LOGINFO)
    self.pause()
    # xbmc.executebuiltin(PlayerControl(Pause))
    # xbmcgui.Dialog().notification('PlayerEvent', 'started')
    xbmc.log(msg='::: Title: ' + xbmc.getInfoLabel('Player.Title') , level=xbmc.LOGINFO)


def my_callback(channel):
    # Here, alternatively, an application / command etc. can be started.
  xbmc.log(msg='::: There was a movement!', level=xbmc.LOGINFO)
  try:
    if player.PAUSED:
      xbmc.log(msg='::: Player isPAUSED!', level=xbmc.LOGINFO)
      xbmc.log(msg='::: isPAUSED 2!', level=xbmc.LOGINFO)
      #player.play()
      xbmc.executebuiltin('PlayerControl(Play)')
      player.PAUSED = False
    else:
      xbmc.log(msg='::: Player notPAUSED!', level=xbmc.LOGINFO)
  except SyntaxError:
      xbmc.log(msg='::: Player EEPT-PAUSED!' + SyntaxError,  level=xbmc.LOGINFO)


player=PIMplayer()
setUpGPIO()
player.play('/media/OF/ZIK/Contents/5221-Iroasztal-Folott-film-master-v01-1080p-stretch.mp4')
player.pause()
xbmc.executebuiltin('PlayerControl(RepeatOne)')

monitor = xbmc.Monitor()
while not monitor.abortRequested():
  try:
    if monitor.waitForAbort(1):
      if DEBUG:
        xbmc.log(msg=':: Title:  '  + xbmc.getInfoLabel('Player.Title') , level=xbmc.LOGINFO)
        xbmc.log(msg=':: Volume: '  + xbmc.getInfoLabel('Player.Volume'), level=xbmc.LOGINFO)
        xbmc.log(msg=':: Progress: '+ xbmc.getInfoLabel('Player.Progress') + ' %', level=xbmc.LOGINFO)
  except:
      xbmc.log(msg='::: !!!!!!!!!!!!!!!!  '  + xbmc.getInfoLabel('Player.Volume'), level=xbmc.LOGINFO)
GPIO.cleanup()
