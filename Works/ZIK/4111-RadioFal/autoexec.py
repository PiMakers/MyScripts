"""

Ez a script két parancssori mpg123 lejátszót kezel, RGB leddel.

Változók:

PIN_L: bal bejövő pin
PIN_R: jobb bejövő pin

PIN_RGB_L: bal RGB led pin tömb
PIN_RGB_R: jobb RGB led pin tömb

VOLUMES_L: bal hangerők
VOLUMES_R: jobb hangerők

FILES_L: bal lejátszó fájljai tömbként
FILES_R: jobb lejátszó fájljai tömbként

"""

import sys
sys.path.append('/usr/share/kodi/addons/virtual.rpi-tools/lib')
import RPi.GPIO as GPIO
import os
import time
import subprocess
import socket
import importlib

HOST = socket.gethostname().lower()

# A következő értékeket init után felül lehet majd bírálni a {hostname.py} fájl alapján
PIN_L1 = 14
PIN_L2 = 15
PIN_R1 = 23
PIN_R2 = 24

VOLUMES_L = [100, 100]
VOLUMES_R = [100, 100]

FILES_L = [
  '/storage/videos/4111_01_Magyar_L.mp3',
  '/storage/videos/4111_01_Angol_L.mp3'
  ]

FILES_R = [
  '/storage/videos/4111_02_Magyar_R.mp3',
  '/storage/videos/4111_02_Angol_R.mp3'
  ]

class MPG123:
  def __init__(self):
    # xbmc.log(':: MPG123 init', level = xbmc.LOGWARNING)
    print(':: MPG123 init')
    self.process = None
    self.master = None
    self.slave = None
  
  def play(self, file, volume = 100, fade_in = True):
    #xbmc.log(':: MPG123 playing ' + file, level = xbmc.LOGWARNING)
    print(':: MPG123 playing ' + file)
    self.send_key('q')
    try:
      self.process.terminate()
    except:
      # xbmc.log(':: MPG123 could not terminate process', level = xbmc.LOGWARNING)
      pass
    
    self.master, self.slave = os.openpty()
    self.process = None
    self.process = subprocess.Popen(['mpg123', '-C', file], stdin = self.master)
    if fade_in:
      self.send_key('s')
      for i in range(0, 100):
        self.send_key('-')
        time.sleep(0.01)
      self.send_key('s')
      for i in range(0, volume):
        self.send_key('+')
        time.sleep(0.01)
    else:
      self.send_key('s')
      for i in range(0, 100 - volume):
        self.send_key('-')
      self.send_key('s')

  def stop(self, fade_out = True):
    # xbmc.log(':: MPG123 stopping', level = xbmc.LOGWARNING)
    print(':: MPG123 stopping')
    if fade_out:
      for i in range(0, 100):
        self.send_key('-')
        #xbmc.sleep(10)
        time.sleep(0.01)

    self.send_key('s')

  def quit(self):
    # xbmc.log(':: MPG123 quitting', level = xbmc.LOGWARNING)
    print(':: MPG123 quitting')
    self.send_key('q')

  def send_key(self, key):
    # xbmc.log(':: MPG123 sending key ' + str(key), level = xbmc.LOGWARNING)
    if not self.process == None:
      try:
        os.write(self.slave, bytes(key, 'ascii'))
      except:
        # xbmc.log(':: MPG123 could not send key', level = xbmc.LOGWARNING)
        print(':: MPG123 could not send key')

def left_pressed(channel):
  global player_r, player_l, FILES_L, VOLUMES_L, prev_channel_l, prev_time_l
  current_time = time.time()
  print(':: Left current_time = ' + str(current_time) + 'prev_time_l = ' + str(prev_time_l))
  if ( prev_time_l - current_time ) < 1:
    print(':: TOO FAST PRESS OCCURED ON ' + str(channel) + ' deltaT= ' + str( prev_time_l - current_time ) )
    prev_time_l = current_time
    return
  if channel == 14:
    idx = 0
  elif channel == 15:
    idx = 1
  # xbmc.log(':: Left pressed, channel = ' + str(channel)+ 'idx = ' + str(idx), level = xbmc.LOGWARNING)  
  print(':: Left pressed, channel = ' + str(channel) + 'idx = ' + str(idx))

  try:
    if player_l.process.poll() is not None:
      # xbmc.log(':: > MPG123 terminated, replaying', level = xbmc.LOGWARNING)
      print(':: > MPG123 terminated, replaying')
      player_l.play(FILES_L[idx], VOLUMES_L[idx], False)
    elif prev_channel_l is not  channel:
      player_l.play(FILES_L[idx], VOLUMES_L[idx], False)
  except:
    # player_l.stop(False)
    player_l.play(FILES_L[idx], VOLUMES_L[idx], False)
  prev_channel_l=channel

def right_pressed(channel):
  global player_r, FILES_R, VOLUMES_R, prev_channel_r, prev_time_r
  current_time = time.time()
  deltaT = (prev_time_l - current_time)
  if ( prev_time_r - current_time ) < 1:
    print(':: TOO FAST PRESS OCCURED ON ' + str(channel) + ' deltaT= ' + str( prev_time_l - current_time ) )
    prev_time_r = current_time
    return
  if channel == 23:
    idx = 0
  elif channel == 24:
    idx = 1
  #xbmc.log(':: Right pressed, channel = ' + str(channel) + 'idx = ' + str(idx), level = xbmc.LOGWARNING)
  print(':: Right pressed, channel = ' + str(channel) + 'idx = ' + str(idx))
  
  try:
    if player_r.process.poll() is not None:
      # xbmc.log(':: > MPG123 terminated, replaying', level = xbmc.LOGWARNING)
      print(':: > MPG123 terminated, replaying')
      player_r.play(FILES_R[idx], VOLUMES_R[idx], False)
    elif prev_channel_r is not  channel:
      player_r.play(FILES_R[idx], VOLUMES_R[idx], False)
  except:
    player_r.play(FILES_R[idx], VOLUMES_R[idx], False)
  prev_channel_r=channel

os.system('pulseaudio -D --system --disallow-exit --disallow-module-loading &')
# xbmc.sleep(2000);
time.sleep(2)
os.system('systemctl restart pulseaudio')
os.system('pactl load-module module-udev-detect')
os.system('pactl set-default-sink 1')
# xbmc.executebuiltin('PlayerControl(RepeatOff)')

#xbmc.executebuiltin('SetVolume(0)')
#xbmc.executebuiltin('PlayMedia(' + os.path.dirname(__file__) + '/back.wav)')
#xbmc.sleep(1000)
time.sleep(1)
os.system('pactl set-sink-volume @DEFAULT_SINK@ 0%')
# xbmc.log(':: Audio init done', level = xbmc.LOGWARNING)
print(':: Audio init done')

if os.path.isfile(os.path.dirname(__file__) + '/' + HOST + '.py'):
  globals().update(importlib.import_module(HOST).__dict__)
  # xbmc.log(':: > Override file loaded', level = xbmc.LOGWARNING)
  print(':: > Override file loaded')
else:
  # xbmc.log(':: > No override file found', level = xbmc.LOGWARNING)
  print(':: > No override file loaded')

print('OVERRIDE FILE: ' + os.path.dirname(__file__) + '/' + HOST + '.py')
player_l = MPG123()
player_r = MPG123()
prev_channel_l=0
prev_channel_r=0
prev_time_l=time.time()
prev_time_r=time.time()

GPIO.setwarnings(False)
GPIO.cleanup()
GPIO.setmode(GPIO.BCM)

GPIO.setup(PIN_L1, GPIO.IN, pull_up_down = GPIO.PUD_DOWN)
GPIO.setup(PIN_L2, GPIO.IN, pull_up_down = GPIO.PUD_DOWN)
GPIO.setup(PIN_R1, GPIO.IN, pull_up_down = GPIO.PUD_DOWN)
GPIO.setup(PIN_R2, GPIO.IN, pull_up_down = GPIO.PUD_DOWN)


GPIO.add_event_detect(PIN_L1, GPIO.RISING, bouncetime = 500, callback = left_pressed)
GPIO.add_event_detect(PIN_L2, GPIO.RISING, bouncetime = 500, callback = left_pressed)
GPIO.add_event_detect(PIN_R1, GPIO.RISING, bouncetime = 500, callback = right_pressed)
GPIO.add_event_detect(PIN_R2, GPIO.RISING, bouncetime = 500, callback = right_pressed)

#xbmc.log(':: Added event handlers', level = xbmc.LOGWARNING)
print(':: Added event handlers')
#xbmc.log(':: Set up pins', level = xbmc.LOGWARNING)
print(':: Set up pins')
monitor = False # xbmc.Monitor()
try:
  while not monitor: #.abortRequested():
    #if monitor.waitForAbort(1):
      #GPIO.cleanup()
    time.sleep(1)
except:
  pass

print(':: CLEANINGUP GPIO')
GPIO.cleanup()