#!/bin/bash
cp /etc/resolv.conf /tmp/resolv.conf
su -c 'umount /etc/resolv.conf'
cp /tmp/resolv.conf /etc/resolv.conf
sed -i 's/DAEMON_ARGS=.*/DAEMON_ARGS=""/' /etc/init.d/expressvpn

# iptables routing
iptables -F
iptables -t nat -A POSTROUTING -o tap+ -j MASQUERADE
iptables -t nat -A POSTROUTING -o tun+ -j MASQUERADE

# expressvpn startup
service expressvpn restart
expect /expressvpn/activate.sh
expressvpn preferences set preferred_protocol lightway_udp
expressvpn preferences set lightway_cipher chacha20
expressvpn preferences set network_lock on
expressvpn preferences set auto_connect true
expressvpn connect $SERVER

# logs
touch /var/log/temp.log
tail -f /var/log/temp.log

exec "$@"
