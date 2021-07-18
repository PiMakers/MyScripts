#!/usr/bin/python

import sys
sys.path.append('/storage/.kodi/addons/virtual.rpi-tools/lib')

import RPi.GPIO as GPIO
import xbmc,xbmcgui

"""
## BCM
button = 14
red    = 15
green  = 18
blue   = 23
"""

## BOARD
button = 8
red    = 16
green  = 12
blue   = 10

baseDir = "/storage/videos/E9-3.3_CivicAssosiation"
global visible
visible = True
srt="/storage/videos/E9-3.3_CivicAssosiation/CivicAssosiationSK.srt"
langID = -1
prevID = -1
ended = 0
paused = False
started = 0
def setUp():
    GPIO.setmode(GPIO.BOARD)
    GPIO.setwarnings(False)
    GPIO.setup(button, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    try: 
       GPIO.add_event_detect(button, GPIO.BOTH, callback=button_callback, bouncetime=300)
    except:
       pass 
    GPIO.setup(red, GPIO.OUT)
    GPIO.setup(green, GPIO.OUT)
    GPIO.setup(blue, GPIO.OUT)

def setLang(ID):

  if ID == 1:
    GPIO.output(red, False)
    GPIO.output(green, True)
    GPIO.output(blue, False)
    xbmc.Player().showSubtitles(False)
  elif ID <= 0
    GPIO.output(red, False)
    GPIO.output(green, False)
    GPIO.output(blue, True)
    xbmc.Player().setSubtitles("/storage/videos/E9-3.3_CivicAssosiation/CivicAssosiationSK.srt")
    xbmc.Player().showSubtitles(True)
  elif ID == 2
    GPIO.output(red, True)
    GPIO.output(green, False)
    GPIO.output(blue, False)
    visible=True
    srt="/storage/videos/E9-3.3_CivicAssosiation/CivicAssosiationEn.srt"

def button_callback(channel):
    if GPIO.input(channel): 
        xbmc.log(msg='****************  Button RISE...', level=xbmc.LOGINFO)
    else:
        xbmc.log(msg='****************  Button FALL...', level=xbmc.LOGINFO)
        if paused:
          xbmc.Player().pause()
        else:
          xbmc.Player().seekTime(5)
        xbmc.Player().setSubtitles(srt)
        if visible:
          xbmc.Player().showSubtitles(True)
        else:
          xbmc.Player().showSubtitles(False)
        ID += 1
        ID = 3%ID
        visible = not visible

class animPlayer(xbmc.Player):

  # ended = 1
  def onPlayBackStarted(self):
    p.seekTime(5)
    while not p.isPlayingVideo():
       xbmc.sleep(200)
    if not paused:
       p.pause()
    xbmcgui.Dialog().notification("PlayerEvent", "onPlayBackSTART" )
    started = 1
    ended = 0
  def onPlayBackEnded(self):
    xbmcgui.Dialog().notification("PlayerEvent", "onPlayBackEND" )
    ended = 1
    started = 0
  def onPlayBackPaused(self):
    xbmcgui.Dialog().notification("PlayerEvent", "onPlayBackPAUSED" )
    paused = True
  def onPlayBackResumed(self):
    xbmcgui.Dialog().notification("PlayerEvent", "onPlayBackRESUMED" )
    paused = False

# class Main:
setUp()
setSK()
p=animPlayer()
p.play('/storage/videos/E9-3.3_CivicAssosiation/CivicAssosiationHU.mp4')
xbmc.executebuiltin( "PlayerControl(repeat)" )
while not p.isPlayingVideo():
  xbmc.sleep(200)
if not paused:
  p.pause()
monitor=xbmc.Monitor()

while not monitor.abortRequested():
   if monitor.waitForAbort(1):
      break

GPIO.cleanup([button, red, green, blue])
