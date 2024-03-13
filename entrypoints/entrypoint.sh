sh ./refresh-addons.sh
[ -e ./enthooks/pre-init.sh ] && sh ./enthooks/pre-init.sh || echo "[Rosmeowtis]: skip pre-init hook"
sh ./init-plugins.sh
[ -e ./enthooks/post-init.sh ] && sh ./enthooks/post-init.sh || echo "[Rosmeowtis]: skip post-init hook"
sh ./run.sh