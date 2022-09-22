# autoexec.py

import os
import sys
import xbmc, xbmcgui



if os.path.exists(f'/storage/script/hname.py'):
    sys.path.append('/storage/script')
    import hname
    hname.main()
    xbmcgui.log(msg=':: autoexec executed!!!!!!!', level=xbmc.LOGINFO)
    xbmcgui.Dialog().notification('AutoExec', "Executed!!!!!!!",5000)
else:
     xbmcgui.log(msg=':: autoexec NOT executed!!!!!!!', level=xbmc.LOGINFO)
     xbmcgui.Dialog().notification('AutoExec', "NOT Executed!!!!!!!",5000)