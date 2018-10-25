# http://ashekhawat.com/rpi-openvpn/

#!/bin/bash
set -e

##########################
## Setting up Raspberry Pi
##########################

# Fetching the LEDE Image
local baseURL="https://downloads.lede-project.org/releases"
local version="17.01.4"

wget ${baseURL}/${version}/targets/brcm2708/bcm2710/lede-${version}-brcm2708-bcm2710-rpi-3-ext4-sdcard.img.gz \
-O /tmp/lede-${version}-brcm2708-bcm2710-rpi-3-ext4-sdcard.img.gz

# Uncompress
gzip -d /tmp/lede-17.01.4-brcm2708-bcm2710-rpi-3-ext4-sdcard.img.gz

# Flashing the LEDE Image

###################
## Configuring LEDE
###################

# Accessing Raspberry Pi

ssh root@192.168.1.1

# Modifying network configuration
 /etc/config/network.
# We will modify the lan interface and add two new interfaces to achieve our goal, leaving the other interfaces unchanged.

config interface 'lan'
    option ifname 'eth0'
    option proto 'dhcp'

config interface 'tun0'
    option ifname 'tun0'
    option proto 'none'

config interface 'wireless'
    option proto 'static'
    option ipaddr '10.0.0.1'
    option netmask '255.255.255.0'
    option ip6assign '60'

To use a static IP instead of using DHCP to obtain an IP from the router use the following configuration for the lan interface. Here is an example of assigning an IP 192.168.1.10 to the RPi for a router that provides IP’s in the 192.168.1.x range and has netmask 255.255.255.0.

config interface 'lan'
    option ifname 'eth0'
    option proto 'static'
    option ipaddr '192.168.1.10'
    option netmask '255.255.255.0'

# Modifying wireless configuration
/etc/config/wireless.
# The wireless adapter is disabled by default. Remove the line option disabled 1 or change 1 to 0 to enable the wireless adapter. Modify the default_radio0 wireless interface to the following (replace your_ssid and your_password with the name and the password you would like to give your wireless access point).

config wifi-iface 'default_radio0'
    option device 'radio0'
    option mode 'ap'
    option encryption 'psk2'
    option key 'your_password'
    option ssid 'your_ssid'
    option network 'wireless'

# Modifying dhcp configuration
/etc/config/dhcp.
# We will add another dhcp configuration for the wireless interface we defined in the networks file so that client which connect to the AP are assigned IPs using DHCP.

config dhcp 'wireless'                           
    option interface 'wireless'              
    option start '100'                       
    option limit '150'                       
    option leasetime '12h'                   
    option dhcpv6 'server'                   
    option ra 'server'

#Modifying firewall configuration
/etc/config/firewall.
# We will first define a zone with input, output and forward rules for the wireless interface we defined in the networks file.

config zone                      
    option name             wireless  
    list network            'wireless'
    option input            ACCEPT
    option output           ACCEPT      
    option forward          ACCEPT

# We will add a similar zone for the tunnel interface using by the VPN.

config zone                                
    option name             tun0       
    list network            'tun0'    
    option input            REJECT          
    option output           ACCEPT    
    option forward          REJECT    
    option masq             1

# The last thing we need to add to configuration file is forwarding packets from wireless client to the VPN.

config forwarding                                      
    option src              lan                
    option dest             wan

# Reflecting changes to the configuration files
# Execute the following commands on the RPi.

/etc/init.d/firewall restart   
wifi up
/etc/init.d/network restart

#Connecting Raspberry Pi to the internet
# We can now unplug the RPi from the computer and connect it to the LAN port of a router. If you chose dhcp for the lan interface, for your RPi to get an IP, DHCP should be enabled on the router. Check your router web interface to obtain the IP assigned to your RPi. If the RPi is assigned the IP 192.168.1.10 for instance, execute the following command on your computer, connected to the same router, to log back into your router.

ssh root@192.168.1.10

# Updating packages and installing LuCI
# Once connected to the router, your RPi should be able to access the internet. Update the packages and install LuCI for web configuration by executing the following commands. You can now access your RPi’s configuration, similar to a conventional router, by keying in its IP.

opkg update
opkg install luci

#####################
## Setting up OpenVPN
#####################

#Installing OpenVPN
opkg install openvpn-openssl

# Transferring .ovpn VPN configuration
# Transfer the .ovpn configuration for VPN to your RPi using the following command, replacing vpn_config_file.ovpn is your configuration file and 192.168.1.10 by your RPi’s IP.

scp vpn_config_file.ovpn root@192.168.1.10:~

# Modifying OpenVPN configuration
/etc/config/openvpn.

# Modify the custom_config configuration to the following

config openvpn custom_config

    # Set to 1 to enable this instance:
    option enabled 1

    # Include OpenVPN configuration
    option config vpn_config_file.ovpn

# Enabling autostart and VPN
# Now that all required configuration in place, we can enable autostart at boot. Finally we enable OpenVPN to get it running right away.

/etc/init.d/openvpn enable
/etc/init.d/openvpn start

# Wrapping it up
echo "The Raspberry Pi is now running as a router with OpenVPN. If you set it up to use DHCP for the ethernet connection and enabled autostart at boot you now have a nifty plug and play box which you can connect to an ethernet port to gain secure internet access through VPN, on your wireless devices."


