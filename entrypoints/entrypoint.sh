bash ./refresh-addons.sh
[ -e ./enthooks/pre-init.sh ] && bash ./enthooks/pre-init.sh || echo "[Rosmeowtis]: skip pre-init hook"
bash ./init-plugins.sh
[ -e ./enthooks/post-init.sh ] && bash ./enthooks/post-init.sh || echo "[Rosmeowtis]: skip post-init hook"
#bash ./update.sh
bash ./run.sh
