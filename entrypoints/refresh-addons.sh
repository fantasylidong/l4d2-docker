# 把 /map 中的文件软连接到游戏的 addons 目录中
# /map 最好作为一个挂载点
for i in $(ls /map); do
    ln -sf /map/$i l4d2/left4dead2/addons/
done

# 另外，由于镜像还将会从 addons 目录中将
# advertisements*
# admins_simple.ini
# shared_plugins.cfg
# 文件复制到对应的地方，为了避免这些文件与地图混放导致不好管理，再提供一个 /sm_configs 目录作为挂载点

for i in $(ls /sm_configs); do
    ln -sf /sm_configs/$i l4d2/left4dead2/addons/
done

echo "[Init] 刷新了 l4d2/left4dead2/addons 中的软连接"