# Borsi Indulók

# SRC_DIR=/usr/share/kodi/addons/skin.estuary/xml
# DST_DIR=/storage/.kodi/addons/skin.estuary_Borsi/xml
# egrep "UTF|window>" ${SRC_DIR}/DialogExtendedProgressBar.xml > ${DST_DIR}/DialogExtendedProgressBar.xml
# /.kodi/addons/skin.estuary_Borsi/xml/DialogSeekBar.xml
# ./.kodi/addons/skin.estuary_Borsi/xml/VideoOSD.xml
# ./.kodi/addons/skin.estuary_Borsi/xml/DialogBusy.xml
# ./.kodi/addons/skin.estuary_Borsi/xml/Home.xml

# Borsi Indulók

import xbmc
import xbmcgui

class ButtonPlayer(xbmc.Player):
  def __init__(self):

    self.started = True
    self.ended = True
    self.debug = True

    self.SeekTime = float(0.0)
    self.modCurrent = 0

    xbmc.executebuiltin('PlayMedia(/storage/.kodi/userdata/playlists/video/zik.m3u)')
    xbmc.executebuiltin('PlayerControl(RepeatAll)')
    # xbmc.executebuiltin('ActivateWindow(VideoOSD.xml)')

    monitor = xbmc.Monitor()

    while not monitor.abortRequested():
      monitor.waitForAbort(1)
#      xbmc.executebuiltin('PlayerControl(Stop)')

  def initVideo(self):
    while not self.isPlayingVideo():
      xbmc.sleep(100)
    if self.started:
      if self.debug:
         xbmcgui.Dialog().notification('PlayerEvent', self.getPlayingFile() )
      if "Liszt" in self.getPlayingFile():
         if self.debug:
             xbmcgui.Dialog().notification('PlayerEvent', "LiszFound")
         self.SeekTime = float(4)
      else:
         if self.debug:
             xbmcgui.Dialog().notification('PlayerEvent', "LisztNotFound")
         self.SeekTime = float(2)
      xbmc.sleep(1500)
      if self.ended:
          self.pause()
      self.seekTime(self.SeekTime)
      self.ended = False

  def onPlayBackStarted(self):
    if self.debug:
        xbmcgui.Dialog().notification('PlayerEvent', 'started')
    self.started = True
    self.initVideo()

  def onPlayBackEnded(self):
    if self.debug:
        xbmcgui.Dialog().notification('PlayerEvent', 'ended')
    self.ended = True
    self.started = False
    xbmc.executebuiltin('PlayerControll(Next)')
    self.initVideo()

if __name__ == '__main__':
  xbmc.executebuiltin( "SetVolume(100)" )
  ButtonPlayer()


"""
<?xml version="1.0" encoding="utf-8"?>
<window>
        <defaultcontrol always="true">602</defaultcontrol>
        <depth>DepthOSD</depth>
        <controls>
                <include condition="Skin.HasSetting(touchmode)">TouchBackOSDButton</include>
                <control type="group">
                        <include>Animation_BottomSlide</include>
                        <bottom>30</bottom>
<!--                    <top>0</top>    -->
                        <height>180</height>
                        <animation effect="fade" time="200">VisibleChange</animation>

                        <control type="group" id="200">
                                <include>Animation_BottomSlide</include>
                                <control type="grouplist" id="201">
                                        <left>1550</left>
                                        <top>90</top>
                                        <width>100%</width>
                                        <height>135</height>
                                        <itemgap>20</itemgap>
                                        <scrolltime tween="sine">200</scrolltime>
                                        <orientation>horizontal</orientation>
                                        <onup>VolumeUp</onup>
                                        <ondown>VolumeDown</ondown>
                                        <control type="radiobutton" id="600">
                                                <include content="OSDButton">
                                                        <param name="texture" value="osd/fullscreen/buttons/previous.png"/>
                                                </include>
                                                <onclick>PlayerControl(Previous)</onclick>
<!-- -->
                                                <visible>Player.ChapterCount | Integer.IsGreater(Playlist.Length(video),1) | [Player.SeekEnabled + VideoPlayer.Content(livetv)]</visible>
                                        </control>
<!---->
                                        <control type="group" id="698">
                                                <width>76</width>
                                                <height>76</height>
<!-- -->                                        <visible>true | Player.PauseEnabled</visible>
                                                <control type="button" id="602">
                                                        <left>0</left>
                                                        <top>0</top>
                                                        <width>74</width>
                                                        <height>74</height>
                                                        <label></label>
                                                        <font></font>
                                                        <texturefocus colordiffuse="button_focus">osd/fullscreen/buttons/button-fo.png</texturefocus>
                                                        <texturenofocus />
                                                        <onleft>600</onleft>
                                                        <onright>607</onright>
                                                        <onup>VolumeUp</onup>
                                                        <ondown>VolumeDown</ondown>
                                                        <onclick>PlayerControl(Play)</onclick>                               </control>
                                                <control type="image">
                                                        <left>0</left>
                                                        <top>0</top>
                                                        <width>74</width>
                                                        <height>74</height>
                                                        <animation center="38,38" effect="zoom" end="100" reversible="false" start="95" time="480" tween="back" condition="Control.HasFocus(602)">Conditional</animation>
                                                        <texture colordiffuse="white">$VAR[PlayerControlsPlayImageVar]</texture>
                                                </control>
                                        </control>
<!-- -->
                                        <control type="radiobutton" id="607">
                                                <include content="OSDButton">
                                                        <param name="texture" value="osd/fullscreen/buttons/next.png"/>
                                                </include>
                                                        <onleft>600</onleft>
                                                        <onright>607</onright>
                                                        <onup>VolumeUp</onup>
                                                        <ondown>VolumeDown</ondown>
                                                <onclick>PlayerControl(Next)</onclick>
                                                <visible>true | Player.ChapterCount | Integer.IsGreater(Playlist.Length(video),1) | PVR.IsTimeShift</visible>
                                        </control>
<!-- -->
                                </control>
                        </control>
                </control>
        </controls>
</window>
"""