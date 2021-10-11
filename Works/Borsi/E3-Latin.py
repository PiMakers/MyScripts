# Borsi E3-Latin

import sys

import xbmc

class ProxyPlayer(xbmc.Player):
  def __init__(self):
    self.started = False
    xbmc.executebuiltin('PlayerControl(RepeatOff)')
    monitor = xbmc.Monitor()
    while not monitor.abortRequested():
      if not monitor.waitForAbort(1):
         self.onProxyTrigger()

  def onProxyTrigger(self):
    if not self.started:
      xbmc.sleep(300000)             # ms
      self.started = True
      self.play('/storage/videos/E2-piocak')

  def onPlayBackEnded(self):
    self.started = False

if __name__ == '__main__':
  ProxyPlayer()


  # xmlstarlet ed --omit-decl --inplace -s settings -t elem -n setting -v "maroon" -i settings/setting -t attr -n id -v lookandfeel.skincolors $KODI_ROOT/userdata/guisettings.xml