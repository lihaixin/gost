# 利用Gost打造加速游戏服务器

## 0、为什么要用游戏加速路由器

外面很多针对于国内游戏玩家，海外游戏玩家，都是在客户端配置，也就是我们PC端安装一个程序，对于个人玩家基本满足，因为个人玩家对网络要求不高，而对于游戏工作室来讲，可能效率就低了，也不稳定，下面这个项目是针对同行大量验证，效果非常不错，价值$5000元，现在分享出来

分五部分内容：

1、服务器端配置

2、openwrt加速路由器配置

3、PC端配置

其他假设：

1. 本地用户网段：192.168.2.0/24
2. openwrt加速路由器IP：192.168.2.201
3. 海外服务器IP：112.112.112.112

## 一、网络环境测试

### 1.1服务器环境

首先在服务器端安装socat和iperf3,用于测试udp丢包率和能跑上的速度

有两种方法：

方法一：

```bash
服务器端部署：
apt install socat iperf3
socat -v UDP-LISTEN:4000,fork PIPE &
nohup iperf3 -s &
```

方法二：

直接使用下面docker 容器，自动开启了iperf3和socat

```bash
docker run -d \
   --name wg0 \
   -e SERVER_PORT=80 -e LANRANGE=192.168.2.0/24 \
   -e FEC_OPTIONS="2:2" \
   -e TIMEOUT=1 \
   -e WGNAME=wg0 \
   -e UDPMTU=1360 \
   -e mtu=1300 \
   -e WANNAME=ens5  \
   -e WGCLIENTIP=10.1.0.2/32 -e WGSERVERIP=10.1.0.1/32 -e WGRANGE=10.1.0.0/24 \
   --cap-add net_admin --cap-add sys_module \
   --restart=always  --net=host --privileged  \
   lihaixin/wireguard:stretch
```

### 1.2openwrt测试

```bash
openwrt客户端测试：
IP=<ip>
ping $IP -c 200
udping $IP
iperf3 -c $IP -u -b 100m
测试ICMP和udp丢包率已经传输带宽

然后根据丢包率和能跑起的带宽配置方案
```

## 二、服务器端

服务器直接使用docker部署

```bash
docker pull lihaixin/gost
docker stop gostvpn && docker rm gostvpn
docker run -itd --name  gostvpn \
--privileged \
-p 4099:4096/udp \
-e LANRANGE="192.168.2.0/24" \
-e MODE=1 \
-e FEC_OPTIONS="2:4" \
-e PASSWORD=password \
-e TIMEOUT=1 \
-e GOSTMTU=1300 \
-e MTU=1360 \
-e INTERVAL=4 \
-e OPTION="--disable-obscure" \
--restart=always \
lihaixin/gost

丢包率在<10%
echo mode 1 > /root/fifo.file
echo fec 4:1 > /root/fifo.file
echo timeout 1 > /root/fifo.file
echo mtu 1360 > /root/fifo.file
ifconfig tun0 mtu 1300

丢包率在<20%
echo mode 1 > /root/fifo.file
echo fec 2:2 > /root/fifo.file
echo timeout 1 > /root/fifo.file
echo mtu 1360 > /root/fifo.file
ifconfig tun0 mtu 1300

丢包率在<40%
echo mode 1 > /root/fifo.file
echo fec 2:4 > /root/fifo.file
echo timeout 1 > /root/fifo.file
echo mtu 1360 > /root/fifo.file
ifconfig tun0 mtu 1300

更多fec参数：
1:2,2:4,8:6,20:10
1:4,2:5,10:14,20:20,100:82
```

## 三、国内机房中转配置

### 先下载：

```bash
wget https://github.com/wangyu-/UDPspeeder/releases/download/20210116.0/speederv2_binaries.tar.gz
tar zxvf speederv2_binaries.tar.gz
mv speederv2_amd64 /usr/bin/speederv2
chmod +x /usr/bin/speederv2

wget --no-check-certificate "https://github.com/ginuerzh/gost/releases/download/v2.11.1/gost-linux-amd64-2.11.1.gz"
gzip -d gost-linux-amd64-2.11.1.gz
mv gost-linux-amd64-2.11.1 /usr/bin/gost
chmod +x /usr/bin/gost
```

### 运行

```bash

#参数记得和服务器端一致
tmux new-session -d -s udp 'speederv2 -c -l0.0.0.0:8338 -r<ip>:4096 --mode 1 --fec 2:4 -k password --timeout 1ms  --mtu 1300 --interval 4 --disable-obscure --fifo /tmp/fifo.file'
tmux new-session -d -s gost 'gost -L tun://:8421/127.0.0.1:8338?net=192.168.123.2/24&tcp=true'

```

## 四、本地openwrt配置

第一步：删除openwrt 防火墙(可选)

```bash
uci delete firewall.@zone[1]
uci delete firewall.@zone[0]
uci set firewall.@defaults[0].forward='ACCEPT'
uci commit
/etc/init.d/firewall restart
```

第二步：把服务器ip添加到静态路由里

```bash
sleep 15
gostip=112.112.112.112
GATEWAY=`uci get network.lan.gateway`
ip route add $gostip via $GATEWAY dev br-lan proto static
```

第三步：添加下面语句到启动项

```bash
udpspeeder -c -l0.0.0.0:8338 -r $gostip:4099 --mode 1 --fec 4:1 -k sanjin --timeout 1ms --mtu 1360 --interval 4 --disable-obscure  --fifo /root/fifo.file &
sleep 1
gost -L tun://:8421/127.0.0.1:8338?net=192.168.123.2/24&tcp=true &
sleep 10
ifconfig tun0 mtu 1300
ip route add 
ip route delete default
ip route add default via 192.168.123.1
echo ok

```

第四步：添加sqm，选择tun0做

```bash
uci set sqm.eth1.interface='tun0'
uci set sqm.eth1.download='5000'
uci set sqm.eth1.upload='5000'
uci set sqm.eth1.enabled='1'
uci commit
/etc/init.d/sqm restart
```

### 五、模拟测试

```bash
服务器模拟丢包和抖动
tc qdisc del dev ens5 root
tc qdisc add dev ens5 root handle 1:0 netem delay 50ms 20ms 30%
tc qdisc add dev ens5 parent 1:1 handle 10: netem loss 30% 15%

```

## 六、定制联系：

V：muzi400
