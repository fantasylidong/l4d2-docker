# 求生之路2 Docker 镜像，含 Anne 插件

## 启动方法

可以使用 docker 或 podman 直接按 docker-compose.yml 文件启动。
docker-compose.yml 文件中提供了一个经验证可正常运行的服务器配置，如果有自定义需求可参照更改。

如果你不想克隆这个仓库，可以去把 [docker-compose.yml](docker-compose.yml) 文件单独下载或者复制其中的内容保存在自己的电脑（或服务器）上就可以使用。
如果你想要进一步开发，或者自行构建镜像，需要克隆此仓库。

### 初次启动，使用 up 指令

up 指令会自动完成镜像下载、容器创建的工作。
+ **但如果你的服务器重启过，希望恢复被停止的容器运行，则不要使用 up 指令，这会导致容器被删除后重建，如果你在容器启动后手动修改了其中的文件，这会导致你的成果丢失。**

```sh
# docker
docker compose -f docker-compose.yml up -d
# podman
podman-compose -f docker-compose.yml up -d
```

+ `-f docker-compose.yml` 指定 compose 文件
+ `-d` 启动后后台运行，不连接到当前终端

如果无法下载镜像，也可以自行编译，注意需要 30G 左右的空余硬盘空间（存放临时文件，尤其是下载求生服务端的时候，很容易出现空间不足的错误）。
（由于需要连接 github，因此可能需要你有特殊的网络条件）

由于 podman-compose 还未内置在 podman 内，因此建议使用 pip3 下载：

```sh
pip3 install podman-compose
```

~~如果你觉得用系统级 pip 安装软件可能会破坏OS的依赖关系，并且知道 pipx 等虚拟环境管理器怎么用，那么请相信你自己。~~

### 二次启动

在因各种原因，已经创建的容器被停止后，恢复启动应使用 start 指令。

```sh
# docker
docker compose -f docker-compose.yml start anne1
# podman
podman-compose -f docker-compose.yml start anne1
```

anne1 是容器名，可通过 `docker container ls --all` 查看已停止的容器信息。（podman 指令类似，把 docker 替换成 podman 就行），这个名称和 compose 文件内的 `container_name` 设定是相同的。

### 刷新三方图、管理员配置

可使用脚本 refresh-addons.sh 刷新容器内 addons 目录下的软连接。使用指令：

```sh
docker container exec anne1 sh ./refresh-addons.sh
# 或者
podman container exec anne1 sh ./refresh-addons.sh
```

同样的，anne1 是容器名。

## 更新服务器

1. 从 docker.io 获取更新。

这需要你能连接到 docker.io 或者其镜像，迷迭香修改了 Dockerfile 文件，`morzlee/l4d2` 将 2.2.3.4 版本的求生服务端纳入了持久缓存，在初次拉取镜像后，再更新镜像只需要下载一些较小的增量层。

```sh
# docker
docker pull morzlee/l4d2
# podman
podman pull morzlee/l4d2
# 或者用 compose
docker compose -f docker-compose.yml pull
podman-compose -f docker-compose.yml pull
```

2. 自行构建。

克隆此仓库后，修改 `docker-compose.yml` 中的 `NEEDUPDATE` 构建参数，然后 build：

```sh
# docker
docker compose -f docker-compose.yml build
# podman
podman-compose -f docker-compose.yml build
```

## 修改服务器启动端口

修改环境变量 `PORT`，示例 compose 文件使用的端口是 27001，可自行修改为其他值。
PS: 桥接开放端口只有2333：2334

## 主机名称

1. 请首先设置环境变量 hostname，可确认的是 plugin="zone" 或 "pureversus" 的情况下会自行替换；
2. 其他情况需要去docker 容器内的/home/louis/l4d2/left4dead2/addons/sourcemod/config/hostname/文件夹里手动修改。

## Region

为了让steam知道你的服务器地图，设置`REGION` 环境变量，设置的参数从下图中选取：

| Location        | REGION |
| --------------- | ------ |
| East Coast USA  | 0      |
| West Coast USA  | 1      |
| South America   | 2      |
| Europe          | 3      |
| Asia            | 4      |
| Australia       | 5      |
| Middle East     | 6      |
| Africa          | 7      |
| World (Default) | 255    |

e.g. 如果你的服务器在欧洲:

`docker run -e REGION=3`...

## 插件选择

有3种插件可以选择，分别是anne Anne药役单独包、zone Anne药役和药抗包、neko多特、purecoop纯净100t战役和pureversus纯净100tick对抗

sirplease github address: https://github.com/fantasylidong/purecoop
anne Github address: https://github.com/fantasylidong/anne
zone Github address: https://github.com/fantasylidong/CompetitiveWithAnne
neko Github address: https://github.com/fantasylidong/neko
pureversus Github address: https://github.com/fantasylidong/100tickPureVersus

默认插件种类是zone，如果需要修改请自己修改参数

`docker run -e plugin=zone`...

| type            |
| --------------- |
| anne            |
| zone            |
| neko            |
| purecoop        |
| pureversus      |

## 挂载卷

本镜像提供两个挂载点：

+ `/map` 放三方图
+ `/sm_configs` 放 `advertisements*`, `admins_simple.ini`, `shared_plugins.cfg`

### 第三方地图

使用了软连接来解决插件和地图在同一个文件夹不好管理的问题。

你只需要将想挂载的volumes挂载到容器内的/map文件夹里会自动进行软连接。

+ **记得文件只能有一个小数点，backtoschool.2.vpk 这种文件读不出来！！！**
+ **记得文件只能有一个小数点，backtoschool.2.vpk 这种文件读不出来！！！**
+ **记得文件只能有一个小数点，backtoschool.2.vpk 这种文件读不出来！！！**
+ （由于我想当然的认为将地图vpk拆分成材质、非材质两个部分，并且只将非材质.vpk上传到服务器可以节省流量和存储空间，同时按照个人习惯为两个包分别命名为 `map.base.vpk` 和 `map.texture.vpk`，导致我在这个问题上浪费了两个小时，太郁闷了）

## 插件管理员设置

环境变量 `steamid` 所设置的用户将成为初始管理员，并拥有 `99:z` 权限。
如果需要增加新的管理员，建议将 `admins_simple.ini` 文件复制出来，修改后，将其放入要挂载容器的 `/sm_configs` 的文件夹内，这样以便多个容器共享。

steamid 可以在游戏中打开控制台，输入 `status` 指令查询。

steamgroup填写自己群组的值，多个可以用英文逗号连接。

password方便自己使用rcon server manage自己管理。

我为了自己方便，默认值全部写的我自己的值，注意修改。

## 启动命令

裸docker指令（不推荐，建议看最上面的 compose 文件方法）

```ssh
docker run --ulimit core=0 --net=host --memory-swap 1000m -m 700m  -e TZ=Asia/Shanghai -e password="123456" -e steamgroup="123456" -e PORT=2333 -e MAP="c2m1_highway" -e REGION=255 -e plugin="anne" -e steamid="STEAM_1:1:121430603" -v "/keep/annemap":"/map" --name anne --restart=always morzlee/l4d2:latest &
```

+ --net=host 使用本地网络，看你自己需求，也能桥接
+ --memory-swap 1000m -m 700m 内存限制
+ -e TZ=Asia/Shanghai 时区
+ -e password="123456" rcon密码
+ -e steamgroup="123456" 绑定的steam组
+ -e PORT=2333 使用端口[桥接记得这个要对应]
+ -e MAP="c2m1_highway" 初始地图
+ -e REGION=255 设置服务器位置
+ -e plugin="anne" 将使用的插件包名字
+ -e steamid="STEAM_1:1:121430603" 设置管理员id
+ -v "/keep/annemap":"/map" 设置硬盘映射，方便docker启动后软连接第三方地图到docker容器内
+ --name anne 容器名字
+ --restart=always 开机重启（随着docker启动而启动）
+ morzlee/l4d2:latest 镜像名字（这是东的镜像，迷迭香提供的分支镜像名为 `rosmeowtis/anne`）
+ & 在linux里表示后台运行

