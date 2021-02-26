FROM alpine:3.12
LABEL name=gost
MAINTAINER sanjin

ENV WANNAME eth0
ENV SERVER_PORT 8421
ENV LANRANGE "192.168.0.0/24"
ENV GOSTSERVERIP "192.168.123.1/24"
ENV GOSTCLIENTIP "192.168.123.2/24"
ENV GOSTRANGE "10.0.0.0/24"
ENV GOSTNAME tun0
ENV mtu 1300
ENV INTERVAL 15
ENV PASSWORD password
ENV TZ=Asia/Shanghai
ENV FEC_OPTIONS "1:2,2:4,8:6,20:10"
ENV TIMEOUT 4ms

WORKDIR /home

ARG ARCH=amd64
ARG UDPSPEEDER_TAG_NAME=20210116.0
ARG UDPSPEEDER_FILE_NAME=speederv2_binaries.tar.gz
ARG UDPSPEEDER_DL_ADRESS="https://github.com/wangyu-/UDPspeeder/releases/download/$UDPSPEEDER_TAG_NAME/$UDPSPEEDER_FILE_NAME"
ARG UDPSPEEDER_BIN_NAME="speederv2_$ARCH"

ARG GOST_TAG_NAME=2.11.1
ARG GOST_FILE_NAME="gost-linux-amd64-$GOST_TAG_NAME.gz"
ARG GOST_DL_ADRESS="https://github.com/ginuerzh/gost/releases/download/v$GOST_TAG_NAME/gost-linux-$ARCH-$GOST_TAG_NAME.gz"
ARG GOST_BIN_NAME="gost-linux-$ARCH-$GOST_TAG_NAME"

RUN apk update \
 && apk add wget tzdata tar\
 && wget $UDPSPEEDER_DL_ADRESS -O $UDPSPEEDER_FILE_NAME \
 && tar -zxvf $UDPSPEEDER_FILE_NAME \
 && find ./ -type f -not -name "$UDPSPEEDER_BIN_NAME" -delete \
 && mv "/home/$UDPSPEEDER_BIN_NAME" /usr/bin/speederv2 \
 && wget $GOST_DL_ADRESS -O $GOST_FILE_NAME \
 && tar -zxvf $UDP2RAW_FILE_NAME \
 && find ./ -type f -not -name "$UDP2RAW_BIN_NAME" -delete \
 && mv "/home/$UDP2RAW_BIN_NAME" /usr/bin/gost \
 && chmod +x /usr/bin/gost
 
EXPOSE 4096/UDP
 
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
