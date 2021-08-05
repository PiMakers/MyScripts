# Borsi Indulók

import xbmc
import xbmcgui
# import RPi.GPIO as GPIO

class ButtonPlayer(xbmc.Player):  
  def __init__(self):

    self.started = False
    self.ended = False


    self.keyPresses = 0
    self.modCurrent = 0

    xbmc.executebuiltin('PlayMedia(/storage/.kodi/userdata/playlists/video/Borsi.m3u)')
    xbmc.executebuiltin('PlayerControl(RepeatAll)')
    xbmc.executebuiltin('ActivateWindow(VideoOSD.xml)')

    monitor = xbmc.Monitor()

    while not monitor.abortRequested():
      monitor.waitForAbort(1)

  def initVideo(self):
#    self.started = False
    while not self.isPlayingVideo():
      xbmc.sleep(100)
#    xbmc.executebuiltin('ActivateWindow(VideoOSD.xml)')
    # xbmc.sleep(1700)
    if self.started:
      xbmcgui.Dialog().notification('PlayerEvent', self.getPlayingFile() )
      xbmc.sleep(1500)
      self.pause()
      self.seekTime(3.5)



  def onPlayBackStarted(self):
    xbmcgui.Dialog().notification('PlayerEvent', 'started')
    self.started = True
    self.ended = False
    self.initVideo()

  def onPlayBackEnded(self):
    self.ended = True
    self.started = False
    xbmc.executebuiltin('PlayerControll(Next)')
    self.initVideo()

if __name__ == '__main__':
  xbmc.executebuiltin( "SetVolume(100)" )
  ButtonPlayer()