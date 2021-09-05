#!/bin/bash
echo "[$(date -Iseconds)] Firewall is up, everything has to go through the vpn"
docker_network="$(ip -o addr show dev eth0 | awk '$3 == "inet" {print $4}')"

echo "[$(date -Iseconds)] Enabling connection to secure interfaces"
if [[ -n ${docker_network} ]]; then
  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A FORWARD -i lo -j ACCEPT
  iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT
  iptables -A OUTPUT -o tap+ -j ACCEPT
  iptables -A OUTPUT -o tun+ -j ACCEPT
  iptables -t nat -A POSTROUTING -o tap+ -j MASQUERADE
  iptables -t nat -A POSTROUTING -o tun+ -j MASQUERADE
fi

echo "[$(date -Iseconds)] Enabling connection to docker network"
if [[ -n ${docker_network} ]]; then
  iptables -A INPUT -s "${docker_network}" -j ACCEPT
  iptables -A FORWARD -d "${docker_network}" -j ACCEPT
  iptables -A FORWARD -s "${docker_network}" -j ACCEPT
  iptables -A OUTPUT -d "${docker_network}" -j ACCEPT
fi

if [[ -n ${docker_network} && -n ${NETWORK} ]]; then
  gw=$(ip route | awk '/default/ {print $3}')
  for net in ${NETWORK//[;,]/ }; do
    echo "[$(date -Iseconds)] Enabling connection to network ${net}"
    ip route | grep -q "$net" || ip route add to "$net" via "$gw" dev eth0
    iptables -A INPUT -s "$net" -j ACCEPT
    iptables -A FORWARD -d "$net" -j ACCEPT
    iptables -A FORWARD -s "$net" -j ACCEPT
    iptables -A OUTPUT -d "$net" -j ACCEPT
  done
fi

mkdir -p /dev/net
[[ -c /dev/net/tun ]] || mknod -m 0666 /dev/net/tun c 10 200