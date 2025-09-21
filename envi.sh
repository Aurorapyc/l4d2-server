#!/bin/bash

INSTSLL_DIR="/home/server-file/"
STEAMCMD="/home/steam-cli/steamcmd.sh"
APP_ID=222860

echo "正在进行系统软件更新"
cp /etc/apt/sources.list /etc/apt/sources.list.backup \
tee /etc/apt/sources.list > /dev/null << 'EOF'
deb https://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse \
deb-src https://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse \

deb https://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse \
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse \

deb https://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse \
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse \


deb https://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse \
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse \
EOF

dpkg --add-architecture i386 && \
apt update && \
apt-get install -y vim wget tmux lib32gcc-s1 lib32stdc++6 ca-certificates

echo "正在下载并解压steamcmd文件"
mkdir -p /home/steam-cli && cd /home/steam-cli
wget  https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xzvf  steamcmd_linux.tar.gz
rm -rf steamcmd_linux.tar.gz

#执行安装
echo "开始安装L4D2"
"$STEAMCMD" \
    +force_install_dir "$INSTSLL_DIR" \
    +login foreverwarn Az001368 \
    +app_update $APP_ID validate \
    +quit
