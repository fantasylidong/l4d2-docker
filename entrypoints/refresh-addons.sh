# 把 /maps 中的文件软连接到游戏的 addons 目录中
# /maps 最好作为一个挂载点
for i in $(ls /map); do
    ln -sf /map/$i l4d2/left4dead2/addons/
done
