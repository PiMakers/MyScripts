import os

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

os.system('pactl set-sink-volume @DEFAULT_SINK@ 0%')
