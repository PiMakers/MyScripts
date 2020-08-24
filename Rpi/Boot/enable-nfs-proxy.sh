## https://www.systutorials.com/export-nfsv4-server-external-networks/

#the external network is 192.168.0.0/16
#the gateway’s external network IP is 192.168.1.100
#the NFS server’s private/internal IP is 10.2.2.2

#iptables -t nat -A PREROUTING -d 192.168.1.100/32 -p tcp -m tcp --dport 2049 -j DNAT --to-destination 10.2.2.2:2049
#iptables -t nat -A PREROUTING -d 192.168.1.100/32 -p udp -m udp --dport 2049 -j DNAT --to-destination 10.2.2.2:2049
#iptables -t nat -A PREROUTING -d 192.168.1.100/32 -p tcp -m tcp --dport 111 -j DNAT --to-destination 10.2.2.2:111
#iptables -t nat -A PREROUTING -d 192.168.1.100/32 -p udp -m udp --dport 111 -j DNAT --to-destination 10.2.2.2:111

# NAT WSL 
sed '/nameserver/!d;s/[^ ]* //'  /etc/resolv.conf

EXT_NET='192.168.1.0'
GATEAWAY='192.168.1.10'
PROXY_NFS=$(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')    # wsl ip
PROXY_NFS=$(echo $(hostname -I))
PORT=3261
DPORT=${PORT}
SUDO=sudo

nfsportforwarding() {
    ${SUDO} iptables -vt nat $1 PREROUTING -d ${GATEAWAY}/32 -p tcp -m tcp --dport 2049 -j DNAT --to-destination ${PROXY_NFS}:2049
    ${SUDO} iptables -t nat $1 PREROUTING -d ${GATEAWAY}/32 -p udp -m udp --dport 2049 -j DNAT --to-destination ${PROXY_NFS}:2049
    ${SUDO} iptables -t nat $1 PREROUTING -d ${GATEAWAY}/32 -p tcp -m tcp --dport 111 -j DNAT --to-destination ${PROXY_NFS}:111
    ${SUDO} iptables -t nat $1 PREROUTING -d ${GATEAWAY}/32 -p udp -m udp --dport 111 -j DNAT --to-destination ${PROXY_NFS}:111
}

iscsiportforwarding(){
    ${SUDO} iptables -vt nat $1 PREROUTING -d ${GATEAWAY}/32 -p tcp -m tcp --dport ${DPORT} -j DNAT --to-destination ${PROXY_NFS}:${PORT}
    ${SUDO} iptables -L
}

AddWindowsFirewallExceptions() {
    netsh advfirewall firewall add rule name="AAAAAAAAA iSCSI Software Target Service-TCP-3260" dir=in action=allow protocol=TCP localport=3260
    netsh advfirewall firewall add rule name="Microsoft iSCSI Software Target Service-TCP-135" dir=in action=allow protocol=TCP localport=135
    netsh advfirewall firewall add rule name="Microsoft iSCSI Software Target Service-UDP-138" dir=in action=allow protocol=UDP localport=138
    netsh advfirewall firewall add rule name="Microsoft iSCSI Software Target Service" dir=in action=allow program="%SystemRoot%\System32\WinTarget.exe" enable=yes
    netsh advfirewall firewall add rule name="Microsoft iSCSI Software Target Service Status Proxy" dir=in action=allow program="%SystemRoot%\System32\WTStatusProxy.exe" enable=yes
}

