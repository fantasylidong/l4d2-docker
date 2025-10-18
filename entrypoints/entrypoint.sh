# ==== start link watcher (后台守护) ====
# 确保目标目录存在（有些情况下第一次运行还没创建）
mkdir -p /home/louis/l4d2/left4dead2/addons

# 以 louis 身份后台启动（当前就是 louis 用户则不需要切换）
# 输出日志到 /tmp/link_watcher.log，保存守护PID以便将来需要时停止
nohup /usr/local/bin/link_watcher.sh /map /home/louis/l4d2/left4dead2/addons \
  >> /tmp/link_watcher.log 2>&1 & echo $! > /tmp/link_watcher.pid

echo "[entrypoint] link watcher started (pid=$(cat /tmp/link_watcher.pid))"
# ==== end link watcher ====
bash ./refresh-addons.sh
[ -e ./enthooks/pre-init.sh ] && bash ./enthooks/pre-init.sh || echo "[Rosmeowtis]: skip pre-init hook"
bash ./init-plugins.sh
[ -e ./enthooks/post-init.sh ] && bash ./enthooks/post-init.sh || echo "[Rosmeowtis]: skip post-init hook"
#bash ./update.sh
bash ./run.sh
