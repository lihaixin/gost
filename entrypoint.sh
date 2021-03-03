#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#ping 127.0.0.1
gost -L tun://:$SERVER_PORT?net=$GOSTSERVERIP&tcp=true
sleep 2
ifconfig tun0 mtu $GOSTMTU
ip route add $LANRANGE dev $GOSTNAME
iptables -t nat -A POSTROUTING -o $WANNAME -s $LANRANGE -j MASQUERADE
iptables -t nat -A POSTROUTING -o $WANNAME -s $GOSTRANGE -j MASQUERADE
speederv2 -s -l0.0.0.0:4096 -r 127.0.0.1:$SERVER_PORT --mode $MODE --fec $FEC_OPTIONS -k $PASSWORD --timeout $TIMEOUT --mtu=$MTU --fifo /tmp/fifo.file --interval $INTERVAL $OPTION
echo ok
