# 利用Gost打造加速游戏服务器

## 一、服务器端

```bash
docker run -itd --name  gostvpn \
	--privileged \
	-p 4099:4096/udp \
	-e LANRANGE="192.168.2.0/24" \
	-e PASSWORD=password \
	lihaixin/gost
```

## 二、国内机房中转配置

### 先下载：

```bash
wget https://github.com/wangyu-/UDPspeeder/releases/download/20210116.0/speederv2_binaries.tar.gz
tar zxvf speederv2_binaries.tar.gz
mv speederv2_amd64 /usr/bin/speederv2
chmod +x /usr/bin/gost

wget --no-check-certificate "https://github.com/ginuerzh/gost/releases/download/v2.11.1/gost-linux-amd64-2.11.1.gz"
gzip -d gost-linux-amd64-2.11.1.gz
mv gost-linux-amd64-2.11.1 /usr/bin/gost
chmod +x /usr/bin/gost
```

### 运行

```bash
tmux new-session -d -s udp 'udpspeeder -c -l0.0.0.0:8338 -r<ip>:4096 --fec 1:3,2:4,8:6,20:10 -k passwd --timeout 4ms --fifo /root/fifo.file --interval 15'
tmux new-session -d -s gost 'gost -L tun://:8421/127.0.0.1:8338?net=192.168.123.2/24&tcp=true'
```

## 三、本地openwrt配置

第一步：删除openwrt 防火墙

第二步：添加下面语句到启动项

```bash
udpspeeder -c -l0.0.0.0:8338 -r<ip>:4096 --fec 1:3,2:4,8:6,20:10 -k passwd --timeout 4ms --fifo /root/fifo.file --interval 15 &
sleep 1
gost -L tun://:8421/127.0.0.1:8338?net=192.168.123.2/24&tcp=true &
sleep 10
ip route delete default
ip route add default via 192.168.123.1
```
