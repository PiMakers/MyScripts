
## https://askubuntu.com/questions/109413/how-do-i-use-overlayfs
## https://askubuntu.com/questions/143176/overlayfs-reload-with-multiple-layers-migration-away-from-aufs/1083452#1083452
## https://askubuntu.com/questions/699565/example-overlayfs-usage/704358#704358
## https://askubuntu.com/questions/143176/overlayfs-reload-with-multiple-layers-migration-away-from-aufs/1083452#1083452
## https://superuser.com/questions/421663/how-to-force-upperdir-overlayfs-to-reread-reload-lowerdir
## https://yagrebu.net/unix/rpi-overlay.md

cd /tmp

# Create the necessary directories.
mkdir lower upper overlay

# Lets create a fake block device to hold our "lower" filesystem
dd if=/dev/zero of=lower-fs.img bs=4096 count=102400
dd if=/dev/zero of=upper-fs.img bs=4096 count=102400

# Give this block device an ext4 filesystem.
mkfs -t ext4 lower-fs.img
mkfs -t ext4 upper-fs.img

# Mount the filesystem we just created and give it a file
sudo mount lower-fs.img /tmp/lower
sudo chown $USER:$USER /tmp/lower
echo "hello world" >> /tmp/lower/lower-file.txt

# Remount the lower filesystem as read only just for giggles
sudo mount -o remount,ro lower-fs.img /tmp/lower

# Mount the upper filesystem
sudo mount upper-fs.img /tmp/upper
sudo chown $USER:$USER /tmp/upper

# Create the workdir in the upper filesystem and the 
# directory in the upper filesystem that will act as the upper
# directory (they both have to be in the same filesystem)
mkdir /tmp/upper/upper
mkdir /tmp/upper/workdir

# Create our overlayfs mount
sudo mount -t overlay -o lowerdir=/tmp/lower,upperdir=/tmp/upper/upper,workdir=/tmp/upper/workdir none /tmp/overlay


#