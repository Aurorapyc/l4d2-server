# **L4D2 专用服务器容器化部署指南**



## **1. 概述**

本文档详细描述了在 `Ubuntu 22.04` Docker 容器内部部署 `Left 4 Dead 2` 游戏专用服务器的标准流程。该方案通过容器化技术确保环境纯净与部署一致性。



## **2. 先决条件**

- 已安装 `Docker Engine` 和 `Docker Compose` 的 Linux 宿主机。
- 具备基础的 Docker 命令行操作知识。



## **3. 部署步骤**



### **3.1 创建项目结构**

在宿主机上创建项目目录，用于管理容器配置及持久化数据。

```bash
mkdir -p ~/l4d2/server-file
cd ~/l4d2
```



### **3.2 准备部署脚本与配置文件**



#### **3.2.1 创建系统更新与安装脚本 (`envi.sh`)**

```sh
#! /bin/bash

INSTALL_DIR="/home/server-file/"
STEAMCMD="/home/steam-cli/steamcmd.sh"
APP_ID=222860

echo "正在进行系统软件更新"
sudo echo "" | sudo tee /etc/apt/sources.list
sudo tee -a /etc/apt/sources.list > /dev/null << 'EOF'
deb https://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
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
```

tips：

从2024年11月起，使用匿名账户下载L4D2服务器时会报错：ERROR! Failed to install app '222860' (Invalid platform) 

解决办法：使用个人steam账号



#### **3.2.2 创建服务器启动脚本 (`start.sh`)**

此脚本用于启动游戏服务器本身。

```sh
#!/bin/bash

SERVER_DIR="/home/server-file"
cd "$SERVER_DIR"

echo "=========================================="
echo "Launch Left 4 Dead 2 Dedicated Server"
echo "Path: $SERVER_DIR"
echo "Time: $(date)"
echo "=========================================="

./srcds_run \
    -game left4dead2 \
    -insecure \
    +hostport 27015 \
    -condebug \
    +map c1m2_streets \
    +exec server.cfg \
    -nomaster \
    -tickrate 100 \
    +maxplayers 9
```



#### **3.2.3 赋予脚本执行权限**

```bash
chmod +x ~/docker/l4d2/*.sh
```



### 3.3 编写 Docker Compose 配置文件

修改 `docker-compose.yml`，将宿主机脚本挂载到容器内，并指定启动命令。

```yaml
services:
  l4d2-server:
    image: ubuntu:22.04
    container_name: l4d2
    restart: unless-stopped
    mem_limit: 16g
    memswap_limit: 16g
    ports:
       - "27015:27015/udp"
       - "27015:27015/tcp"
    volumes:
      - ./server-file:/home/server-file
      - ./envi.sh:/home/envi.sh
      - ./start.sh:/home/start.sh
    tty: true
    stdin_open: true
```



### 3.4 启动部署

运行以下命令启动整个部署流程。Docker Compose 会自动完成安装和启动。

```bash
docker-compose up -d
```



### 3.5 进入容器控制台

执行以下命令以交互模式进入正在运行的容器内部：

```bash
docker-compose exec -it l4d2 /bin/bash
```



### 4. 部署后配置：安装插件平台与管理员设置

通过 `docker-compose up -d` 成功启动服务器基础环境后，需进行以下管理员配置与插件安装步骤



#### 4.1 下载插件平台

```bash
# 进入宿主机项目目录
cd /home/

# 下载 SourceMod (请访问 https://www.sourcemod.net/downloads.php?branch=stable 获取最新稳定版链接)
wget https://sm.alliedmods.net/smdrop/1.12/sourcemod-1.12.0-git7211-linux.tar.gz

# 下载 MetaMod (请访问 http://metamodsource.net/downloads.php?branch=stable 获取最新稳定版链接)
wget https://mms.alliedmods.net/mmsdrop/1.12/mmsource-1.12.0-git1219-linux.tar.gz
```



#### 4.1.2 解压安装

```bash
# 解压 SourceMod 到临时目录，再合并到游戏目录
tar -xvzf sourcemod-*.tar.gz -C /home/sourcmod
cp -a /home/sourcemod/addions/* /home/server-file/left4dead2/addions
cp -a /home/sourcemod/cfg/* /home/server-file/left4dead2/cfg

# 解压 MeatMod 到临时目录，再合并到游戏目录
tar -xvzf mmsource-*.tar.gz -C /home/sourcemod
cp -a /home/metamod/addions/* /home/server-file/left4dead2/addions
```



### 4.2 配置管理员权限，获取SteamID64



#### 4.2.1 获取**SteamID64**

方法一：打开l4d2游戏进入任意地图关卡，控制台输入status就会显示玩家的steamID

方法二：在浏览器中登录steam网站，打开个人资料页面，将地址栏的网址复制到查询网站的搜索框即可搜索出steamID，SteamID查询网址：https://steamid.io/lookup/ 



#### 4.2.2 设置管理员

```bash
# 在宿主机上编辑 admins_simple.ini 文件
vi /home/server-file/left4dead2/addons/sourcemod/configs/admins_simple.ini

# 在文件末尾添加以下内容（如果文件不存在则创建）,如果还要添加更多管理员，另起一行按同样各式进行书写
"7656119xxxxxxxxxx" "99:z"

# 保存并退出编辑器
```



#### 4.2.3 验证管理员权限

在游戏内按 `Y` 或 `U` 打开聊天框，输入 `!admin`，如果能看到管理员菜单，则说明权限配置成功。



### 4.3 配置 `server.cfg` 文件

```bash
rcon_password "" 					# 远程管理密码
sv_password "" 						# 服务器密码
sv_allow_lobby_connect_only 0		 # 不允许从大厅选择组服务器来连接
sv_tags hidden						# 在服务器浏览列表的中隐藏
sv_gametypes "coop,versus,survival"	  # 服务器游戏模式(coop合作、versus对抗、realism写实、scavenge清道夫)
sm_cvar mp_gamemode coop			 # 设定当前游戏模式为合作战役
z_difficulty Normal					 # 游戏难度：easy简单；normal普通；hard高级；impossible专家
sv_region 4							# 设定服务器地区为亚洲
sv_lan 0							# 非局域网
sv_consistency 0					# 关闭模型(MOD)冲突
motd_enabled 1						# 玩家进入服务器自动打开[今日消息]界面
sv_cheats 0							# 关闭作弊
```



### 4.3.1 启动服务器

方法一：

```bash
# 进入 srcds_run 文件所在目录
cd /home/server-file
./srcds_run -game left4dead2 -insecure +hostport 27015 -condebug +map c1m2_streets +exec server.cfg -nomaster

# 看到 Connection to Steam servers successful. 代表l4d2服务器启动完成
```



方式二

```bash
# 执行 start.sh 启动脚本
./start.sh
```



### 4.4 安装与配置游戏插件



#### 4.4.1 安装 Tickrate Enabler 插件（60Tick / 100 tick）

```bash
# 下载 Tickrate Enabler
wget https://github.com/accelerator74/Tickrate-Enabler/releases/download/build/Tickrate-Enabler-l4d2-linux-db72da3.zip

# 解压 Tickrate Enabler 到临时目录,再合并到游戏目录
unzip Tickrate-Enabler-l4d2-linux-db72da3.zip -d /home/tickrate
cp -a /home/tickrate/addions/* /home/server-file/left4dead2/addions
```



#### 4.4.1.1 修改 `server.cfg` ，添加参数

设置60tick，添加以下命令

```bash
sm_cvar net_splitpacket_maxrate 30000
sm_cvar nb_update_frequency 0.024
sm_cvar tick_door_speed 1.3
sm_cvar fps_max 0
sm_cvar sv_minrate 60000
sm_cvar sv_maxrate 60000
sm_cvar sv_mincmdrate 60
sm_cvar sv_maxcmdrate 60
sm_cvar sv_minupdaterate 60
sm_cvar sv_maxupdaterate 60
sm_cvar sv_client_min_interp_ratio -1
sm_cvar sv_client_max_interp_ratio 2
```

设置100tick，添加以下命令

```bash
sm_cvar net_splitpacket_maxrate 50000
sm_cvar nb_update_frequency 0.024
sm_cvar tick_door_speed 1.3
sm_cvar fps_max 0
sm_cvar sv_minrate 100000
sm_cvar sv_maxrate 100000
sm_cvar sv_mincmdrate 100
sm_cvar sv_maxcmdrate 100
sm_cvar sv_minupdaterate 100
sm_cvar sv_maxupdaterate 100
sm_cvar sv_client_min_interp_ratio -1
sm_cvar sv_client_max_interp_ratio 2
```



#### 4.4.1.2 在 `start.sh` 里添加启动项

```bash
# 设置 60tick
-tickrate 60

# 设置 100tick
-tickrate 100
```



#### 4.4.1.3 客户端配置

在游戏安装路径下的 `\left4dead2\cfg` 目录里新建 `autoexec.cfg`文件并添加以下内容

```bash
rate 30000
cl_cmdrate 100
cl_updaterate 100

# 设置客户端的lerp值
cl_interp_ratio 0
cl_interp 0
```



#### 4.4.2 安装 `Infected's Health gauge is displayed` 显示特感血量插件

```bash
# 将下载到的.smx 文件复制到游戏目录里
cp -a /home/l4d_infectedhp_redux.smx /home/server-file/left4dead2/addions/sourcemod/plugins
```

```bash
【.smx】 插件的核心部分，安装位置为：\left4dead2\addons\sourcemod\plugins
【.cfg】 配置文件，安装位置为：\left4dead2\cfg\sourcemod
【.sp】  源码，可以不用安装，安装位置为：\left4dead2\addons\sourcemod\scripting
【.txt】 安装位置为：\left4dead\addons\sourcemod\gamedata
```



### 4.5 自定义今日消息与服务器提供者



#### 4.5.1 自定义今日消息

```bash
# 新建 motd1.txt,将展示内容写在里面(文本，图片，网页)
vim /home/server-file/left4dead2/motd1.txt
```

```bash
# 修改 server.cfg，添加以下指令
motdfile "motd1.txt"
```



#### 4.5.2 修改服务器提供者名称

```bash
vim /home/server-file/left4dead2/host.txt

# 将名称填写进去即可
```



### 5. 其他事项



#### 5.1 检查`metaplungins.ini`，否则无法加载插件

```bash
cat /home/server-file/left4dead2/addons/metamod/metaplugins.ini
echo "addons/sourcemod/bin/sourcemod_mm" >> /home/server-file/left4dead2/addons/metamod/metaplugins.ini
```



#### 5.2更新l4d2服务器

```bash
vim update_game.sh
```

```sh
#!/bin/bash
./steamcmd.sh \
+force_install_dir /home/server-file \ 
+login anonymous +app_update 222860 \
+quit
```



#### 5.3 Tickerate_Enabler 无法加载

原因：GLIBC 2.31 (Ubuntu 20.04)版本不符合插件需要的2.33

解决办法：使用 (Ubuntu22.04)版本，GLIBC 2.
