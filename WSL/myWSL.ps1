
$DL_DIR=(New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
ls $DL_DIR
curl http://bosmans.ch/pulseaudio/pulseaudio-1.1.zip -o $DL_DIR\pulseaudio-1.1.zip
ls $DL_DIR\pulse*
#Expand-Archive -Force C:\path\to\archive.zip C:\where\to\extract\to
