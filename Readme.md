# 求生之路2 Docker image

## 端口

默认情况下，打开27015端口最合适，为了方便windows用户创建本地docker服务器，还增加了2333和2334两个端口（原因等会介绍）

```
docker run -p 2333:2333/tcp -p 2333:2333/udp -e PORT=2333 -e MAP="c2m1_highway" -e REGION=255 -e HOSTNAME="LEO" -e plugin="anne" -e steamid="STEAM_1:1:121430603" -v "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Left 4 Dead 2\\left4dead2\\addons":"/map" --name anne morzlee/l4d2
```

如果是Windows系统，首先docker pull morzlee/l4d2 把docker镜像拉取出来，然后在在docker创建容器时增加一个volumes对应就行，如下图：

![image-20211219114215492](https://github.com/fantasylidong/AnneServer/blob/main/image-20211219114215492.png)

### 修改服务器启动端口

只需要修改环境变量 `PORT` 即可解决

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

有3种插件可以选择，分别是Anne药役和neko多特和sirplease药抗

sirplease github address: https://github.com/SirPlease/L4D2-Competitive-Rework

Anna Github address: https://github.com/Caibiii/AnneServer 

neko Github address: https://github.com/himenekocn/NekoSpecials-L4D2

默认插件种类是anna，如果需要修改请自己修改参数

`docker run -e plugin=anna`...

| type            |
| --------------- |
| anne            |
| neko            |
| sirplease       |
| custombyyouself |

## 第三方地图

使用了软连接来解决插件和地图在同一个文件夹不好管理的问题

你只需要将想挂载的volumes挂载到容器内的/map文件夹里会自动进行软连接（记得文件只能有一个小数点，backtoschool.2.vpk 这种文件读不出来

## 插件管理员设置

只要设置好环境变量 steamid就可以了，把你在游戏的steamid 写入环境变量

我为了自己方便，默认值全部写的我自己steamid，注意修改
