#!/bin/bash
cp /etc/resolv.conf /etc/resolv.conf.bak
umount /etc/resolv.conf
cp /etc/resolv.conf.bak /etc/resolv.conf
rm /etc/resolv.conf.bak
sed -i 's/DAEMON_ARGS=.*/DAEMON_ARGS=""/' /etc/init.d/expressvpn

/bin/bash /expressvpn/routing.sh
service expressvpn restart
#expect /expressvpn/activate.sh
expressvpn activate $ACTIVATION_CODE
expressvpn preferences set preferred_protocol $PREFERRED_PROTOCOL
expressvpn preferences set lightway_cipher $LIGHTWAY_CIPHER
expressvpn preferences set network_lock on
expressvpn preferences set auto_connect true
expressvpn connect $SERVER

touch /var/log/temp.log
tail -f /var/log/temp.log

exec "$@"
