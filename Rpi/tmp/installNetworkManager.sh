# https://raspberrypi.stackexchange.com/questions/29783/how-to-setup-network-manager-on-raspbian?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa

# I have found how to get NetworkManager (and systemd-resolved) working on Raspbian 9 (Stretch). NetworkManager is very useful when you need to manage multiple VPN connections with split DNS, wifi networks and other advanced network settings directly from the Pixel Desktop.

# Here is how to do it:

# Install the needed packages with the following command:
sudo apt install network-manager \
		network-manager-gnome openvpn \
		openvpn-systemd-resolved \
		network-manager-openvpn \
		network-manager-openvpn-gnome

# Remove unneded packages:
sudo apt purge openresolv dhcpcd5

# Replace /etc/resolv.conf with a symlink to /lib/systemd/resolv.conf :
sudo ln -sf /lib/systemd/resolv.conf /etc/resolv.conf

#Now go to the top of your screen and reconfigure the panel: open "Panel Settings" -> "Panel Applets": remove "Wireless & Wired Network". The network manager applet should appear after a reboot.
