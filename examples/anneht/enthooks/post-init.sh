# 1. 向 hunters.cfg 中插入默认 0 秒和开回血配置
SRCDIR=${HOME}/enthooks
CFGDIR=${HOME}/l4d2/left4dead2/cfg/cfgogl/hunters
CMD1='confogl_addcvar versus_special_respawn_interval 0'
CMD2='confogl_addcvar ReturnBlood 1'
cd ${CFGDIR}
if [ $( cat hunters.cfg | grep "^${CMD1}" || echo "0" ) = "0" ]; then
  echo -e "\n${CMD1}" >> hunters.cfg
  echo "[Rosmeowtis]: 插入 ${CMD1}"
fi
if [ $( cat hunters.cfg | grep "^${CMD2}" || echo "0" ) = "0" ]; then
  echo -e "\n${CMD2}" >> hunters.cfg
  echo "[Rosmeowtis]: 插入 ${CMD2}"
fi
cd -

# 2. 替换 !match 指令，只保留ht训练和单人装逼

cat <<EOF > ${HOME}/l4d2/left4dead2/addons/sourcemod/configs/matchmodes.txt
"MatchModes"
{
        "AnneHappy Configs"
        {
                "hunters"
                {
                        "name" "1vHT模式"
                }
                "alone"
                {
                        "name" "单人装逼模式"
                }
        }
}
EOF
echo "[Rosmeowtis]: 已替换 1vHT 默认配置(2t0s开回血)"