# 求生之路2 Docker image

## 修改服务器启动端口

只需要修改环境变量 `PORT` 即可解决
PS: 桥接开放端口只有2333：2334

## 主机名称

这个请去docker 容器内的/home/louis/l4d2/left4dead2/addons/sourcemod/config/hostname/文件夹里修改

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

默认插件种类是anna，如果需要修改请自己修改参数

`docker run -e plugin=anne`...

| type            |
| --------------- |
| anne            |
| zone            |
| neko            |
| purecoop       |
| pureversus |

## 第三方地图

使用了软连接来解决插件和地图在同一个文件夹不好管理的问题

你只需要将想挂载的volumes挂载到容器内的/map文件夹里会自动进行软连接（记得文件只能有一个小数点，backtoschool.2.vpk 这种文件读不出来

## 插件管理员设置

只要设置好环境变量 steamid就可以了，把你在游戏的steamid 写入环境变量

steamgroup填写自己群组的值，多个可以用英文逗号连接

password方便自己使用rcon server manage自己管理

我为了自己方便，默认值全部写的我自己的值，注意修改

## 启动命令
docker run --ulimit core=0 --net=host --memory-swap 1000m -m 700m  -e TZ=Asia/Shanghai -e password="123456" -e steamgroup="123456" -e PORT=2333 -e MAP="c2m1_highway" -e REGION=255 -e plugin="anne" -e steamid="STEAM_1:1:121430603" -v "/keep/annemap":"/map" --name anne --restart=always morzlee/l4d2:latest &
--net=host 使用本地网络，看你自己需求，也能桥接
--memory-swap 1000m -m 700m 内存限制
-e TZ=Asia/Shanghai 时区
-e password="123456" rcon密码
-e steamgroup="123456" 绑定的steam组
-e PORT=2333 使用端口[桥接记得这个要对应]
-e MAP="c2m1_highway" 初始地图
-e REGION=255 设置服务器位置
-e plugin="anne" 将使用的插件包名字
-e steamid="STEAM_1:1:121430603" 设置管理员id
-v "/keep/annemap":"/map" 设置硬盘映射，方便docker启动后软连接第三方地图到docker容器内
--name anne 容器名字
--restart=always 开机重启（随着docker启动而启动）
morzlee/l4d2:latest 镜像名字
& 在linux里表示后台运行

 
