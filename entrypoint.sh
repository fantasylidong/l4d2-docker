#!/bin/bash
# Update Game
./steamcmd.sh +login anonymous +force_install_dir ./l4d2 +app_update 222860 +quit

#Softlink l4d2 maps to addons folder
#It would more convenience while you want add custom map. Exspecially when you have sourcemod plugins
#you just need mount your extra map folder to docker container /map . 
ln  -s  /map/*  l4d2/left4dead2/addons/
ln  -s  /map2/*  l4d2/left4dead2/addons/
oldpluginpackage(){
	echo "\n\"$steamid\" \"99:z\"" >> /home/louis/l4d2/left4dead2/addons/sourcemod/configs/admins_simple.ini
	echo "sv_steamgroup \"$steamgroup\"" >> /home/louis/l4d2/left4dead2/cfg/server.cfg
	echo "rcon_password \"$password\"" >> /home/louis/l4d2/left4dead2/cfg/server.cfg
}
newpluginpackage(){
	sed -i "s/13333337/$steamgroup/g"  /home/louis/l4d2/left4dead2/cfg/server.cfg
	sed -i "s/CompetitiveRework/annehappy/g" /home/louis/l4d2/left4dead2/cfg/server.cfg
	sed -i "s/WowYouKnowThePasswordHere/$password/g" /home/louis/l4d2/left4dead2/cfg/server.cfg
}
cloudconfig(){
	#cloud server settings
	#插件处理hidden
	#echo "\nsv_tags hidden" >> /home/louis/l4d2/left4dead2/cfg/server.cfg
	#sed -i "s/nb_update_frequency\ 0.014/nb_update_frequency\ 0.024/" /home/louis/l4d2/left4dead2/cfg/server.cfg
	#sed -i "s/fps_max\ 150/fps_max\ 0/" /home/louis/l4d2/left4dead2/cfg/server.cfg
	if [! -n "$serverid" ]
		sed -i "47 s/\"2\"/\"16\"/" /home/louis/l4d2/left4dead2/addons/sourcemod/configs/sourcebans/sourcebans.cfg
	#cp /home/louis/l4d2/left4dead2/addons/hostname.txt /home/louis/l4d2/left4dead2/addons/sourcemod/configs/hostname/
	cp /home/louis/l4d2/left4dead2/addons/advertisements* /home/louis/l4d2/left4dead2/addons/sourcemod/configs/
	cp /home/louis/l4d2/left4dead2/addons/admins_simple.ini /home/louis/l4d2/left4dead2/addons/sourcemod/configs/
}

localconfig(){
	rm /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/optional/specrates.smx
	sed -i "s/fps_max\ 0/fps_max\ 150/" /home/louis/l4d2/left4dead2/cfg/server.cfg
	if [ "$PORT" = "2330" ];
	then
		#git -C /home/louis/CompetitiveWithAnne/ checkout test
		cp  -r /home/louis/CompetitiveWithAnne/* l4d2/left4dead2/
		rm /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/optional/AnneHappy/sam_vs.smx
		sed -i "256 s/-secure/-insecure/"  /home/louis/entrypoint.sh
		sed -i "s/join_autoupdate\ 1/join_autoupdate\ 0/g" /home/louis/l4d2/left4dead2/cfg/cfgogl/*/shared_settings.cfg
		sed -i "s/join_autoupdate\ 4/join_autoupdate\ 0/g" /home/louis/l4d2/left4dead2/cfg/cfgogl/*/shared_settings.cfg
		echo "sm_cvar join_autoupdate 0" >> /home/louis/l4d2/left4dead2/cfg/server.cfg
	fi
	if [ "$PORT" = "2340" ];
	then
		sed -i 's/AnneHappy6.cfg/AnneHappy4.cfg/g' /home/louis/l4d2/left4dead2/cfg/cfgogl/annehappy/confogl_plugins.cfg
		sed -i 's/ai_Tank_StopDistance\ 135/ai_Tank_StopDistance\ 145/' /home/louis/l4d2/left4dead2/cfg/vote/hard_off.cfg
		sed -i 's/ai_TankAirAngleRestrict\ 57/ai_TankAirAngleRestrict\ 60/' /home/louis/l4d2/left4dead2/cfg/vote/hard_off.cfg
	fi
	if [ "$PORT" = "2341" ];
	then
		sed -i 's/AnneHappy6.cfg/AnneHappy5.cfg/g' /home/louis/l4d2/left4dead2/cfg/cfgogl/annehappy/confogl_plugins.cfg
		sed -i 's/ai_Tank_StopDistance\ 135/ai_Tank_StopDistance\ 140/' /home/louis/l4d2/left4dead2/cfg/vote/hard_off.cfg
		sed -i 's/ai_TankAirAngleRestrict\ 57/ai_TankAirAngleRestrict\ 60/' /home/louis/l4d2/left4dead2/cfg/vote/hard_off.cfg
	fi
	if [ "$PORT" = "2342" ];
	then
		sed -i 's/ai_Tank_StopDistance\ 135/ai_Tank_StopDistance\ 135/' /home/louis/l4d2/left4dead2/cfg/vote/hard_off.cfg
		sed -i 's/ai_TankAirAngleRestrict\ 57/ai_TankAirAngleRestrict\ 60/' /home/louis/l4d2/left4dead2/cfg/vote/hard_off.cfg
	fi
}
copydanceresource(){
	cp -r /home/louis/anne/left4dead2/sound/ l4d2/left4dead2/
	cp -r /home/louis/anne/left4dead2/models/ l4d2/left4dead2/
}
anneremovemysql(){
	#修改hostname插件端口对应port环境变量
	if [ -n "$PORT" ]
	then
		sed -i "s/2330/$PORT/g" /home/louis/l4d2/left4dead2/addons/sourcemod/configs/hostname/hostname.txt
	fi
	
	if [ -n "$hostname" ]
	then
		sed -i "s/Anne电信测试服/$hostname/g" /home/louis/l4d2/left4dead2/addons/sourcemod/configs/hostname/hostname.txt
	fi
	
	if [ -n "$mysqlexist" ]
	then
		rm /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/extend/l4d_stats.smx
                rm /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/chat-processor.smx
                rm /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/extend/hextags.smx
                rm /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/extend/lilac.smx
                rm /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/extend/sbpp_*
                rm /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/extend/rpg.smx
                rm /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/extend/chatlog.smx
                rm /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/extend/veterans.smx
                cp /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/disabled/rpg.smx /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/extend/
	fi
}
# plugins Config
if [ ! -d "/home/louis/l4d2/left4dead2/addons/sourcemod/" ];
then
	if [ "$plugin" = "anne" ];
	then
		cp  -r /home/louis/anne/* l4d2/
		if [ "$cloud" = "true" ];
		then
			cloudconfig
		else
			localconfig
		fi
		oldpluginpackage
		echo "anne plugins packge installed"
	fi

	if [ "$plugin" = "purecoop" ];
	then
		cp  -r /home/louis/purecoop/* l4d2/left4dead2/
		echo "purecoop plugins packge installed"
		oldpluginpackage
	fi


	if [ "$plugin" = "neko" ];
	then
		cp  -r /home/louis/neko/* l4d2/left4dead2/
		copydanceresource
		echo "neko plugins packge installed"
		oldpluginpackage
	fi
	
	if [ "$plugin" = "zone" ];
	then
		cp  -r /home/louis/CompetitiveWithAnne/* l4d2/left4dead2/
		# nav file copy
		cp -r /home/louis/anne/update/* l4d2/update/
		copydanceresource
		echo "zone plugins packge installed"
		sed -i "s/join_autoupdate\ 1/join_autoupdate\ 4/g" /home/louis/l4d2/left4dead2/cfg/cfgogl/*/shared_settings.cfg
		if [ "$cloud" = "true" ];
		then
			cloudconfig
		else
			localconfig
		fi
		anneremovemysql
		newpluginpackage
		if [ -n "$PLAYERS" ]
		then
			sed -i "s/mv_maxplayers\ 8/mv_maxplayers\ $PLAYERS/g" /home/louis/l4d2/left4dead2/cfg/server.cfg
		fi
	fi
	
	if [ "$plugin" = "pureversus" ];
	then
		cp  -r /home/louis/100tickPureVersus/* l4d2/left4dead2/
		copydanceresource

                #if [ "$PORT" = "2341" ];
		#then
		#	sed -i 's/mutation12/versus/g' /home/louis/l4d2/left4dead2/cfg/server.cfg
		#fi

                #if [ "$PORT" = "2342" ];
		#then
		#	sed -i 's/mutation12/versus/g' /home/louis/l4d2/left4dead2/cfg/server.cfg
		#fi
		
		if [ -n "$PORT" ]
		then
			sed -i "s/2351/$PORT/g" /home/louis/l4d2/left4dead2/addons/sourcemod/data/hostname.txt
		fi

		if [ -n "$hostname" ]
		then
			sed -i "s/电信服进阶写实包抗/$hostname/g" /home/louis/l4d2/left4dead2/addons/sourcemod/data/hostname.txt
		fi
		
		echo "pure versus packge installed"
		oldpluginpackage
	fi
	
	#if [ "$cloud" = "false" ];
	#then
	#	#localserver change to static local ip
	#	sed -i 's/home.trygek.com/10.0.0.4/g' /home/louis/l4d2/left4dead2/addons/sourcemod/configs/databases.cfg
	#	sed -i 's/12345/3306/g' /home/louis/l4d2/left4dead2/addons/sourcemod/configs/databases.cfg
	#fi
	
	#region setting
	echo "\nsv_region \"$REGION\"" >> /home/louis/l4d2/left4dead2/cfg/server.cfg
	if [ -n "$steamid" ]
	then
		echo "\n\"$steamid\" \"99:z\"" >> /home/louis/l4d2/left4dead2/addons/sourcemod/configs/admins_simple.ini
	fi
	
	#server language setting
	if [ -n "$lang" ]
	then
		sed -i "s/\"ServerLang\"\	\"en\"/\"ServerLang\"\	\"$lang\"/g" /home/louis/l4d2/left4dead2/addons/sourcemod/configs/core.cfg
	else
		sed -i "s/\"ServerLang\"\	\"en\"/\"ServerLang\"\	\"chi\"/g" /home/louis/l4d2/left4dead2/addons/sourcemod/configs/core.cfg
	fi
	
	#修改accelator log report
	if [ -n "$steam64" ]
	then
		sed -i "s/1111111111/$steam64/g" /home/louis/l4d2/left4dead2/addons/sourcemod/configs/core.cfg
	fi
	
	#修改updaterfrequence
	if [ -n "$freqency" ]
	then
		sed -i "s/nb_update_frequency\ 0.024/nb_update_frequency\ 0.0$freqency/" /home/louis/l4d2/left4dead2/cfg/server.cfg
	fi
	
	#修改数据库地址
	if [ -n "$mysql" ]
	then
		sed -i "s/home.trygek.com/$mysql/g" /home/louis/l4d2/left4dead2/addons/sourcemod/configs/databases.cfg
	fi
	
	#修改数据库端口
	if [ -n "$mysqlport" ]
	then
		sed -i "s/12345/$mysqlport/g" /home/louis/l4d2/left4dead2/addons/sourcemod/configs/databases.cfg
	fi
	
	#修改数据库用户名
	if [ -n "$mysqluser" ]
	then
		sed -i "s/morzlee/$mysqluser/g" /home/louis/l4d2/left4dead2/addons/sourcemod/configs/databases.cfg
	fi
	
	#修改数据库密码
	if [ -n "$mysqlpassword" ]
	then
		sed -i "s/anne123/$mysqlpassword/g" /home/louis/l4d2/left4dead2/addons/sourcemod/configs/databases.cfg
	fi
	
	#修改模型下载链接
	if [ -n "$mysqlpassword" ]
	then
		sed -i "s/sb.trygek.com/$dlurl/g" /home/louis/l4d2/left4dead2/cfg/server.cfg
	fi
	
	#private,把服务器设为只允许组员第一个进入
	if [ -n "$private" ]
	then	
		if [ "$plugin" = "zone" ];
		then
			sed -i "s/sm_cvar\ sv_steamgroup_exclusive/\/\/sm_cvar\ sv_steamgroup_exclusive/g" /home/louis/l4d2/left4dead2/cfg/server.cfg
			sed -i "s/sv_steamgroup_exclusive/\/\/sv_steamgroup_exclusive/g" /home/louis/l4d2/left4dead2/cfg/server.cfg
			echo "sm_cvar join_enable_autolobbycontrol 1" >> /home/louis/l4d2/left4dead2/cfg/server.cfg
		else
			sed -i "s/sm_cvar\ sv_steamgroup_exclusive\ 0/sm_cvar\ sv_steamgroup_exclusive\ 1/g" /home/louis/l4d2/left4dead2/cfg/server.cfg
			sed -i "s/sv_steamgroup_exclusive\ 0/sv_steamgroup_exclusive\ 1/g" /home/louis/l4d2/left4dead2/cfg/server.cfg
		fi
	fi
	
	if [ "$lobby" = "true" ];
	then
		sed -i "s/sv_allow_lobby_connect_only/\/\/sv_allow_lobby_connect_only/g" /home/louis/l4d2/left4dead2/cfg/server.cfg
		echo "sm_cvar sv_hosting_lobby 1" >> /home/louis/l4d2/left4dead2/cfg/server.cfg
		if [ "$plugin" = "zone" ];
		then
			sed -i "/sm_killlobbyres/d" /home/louis/l4d2/left4dead2/cfg/cfgogl/*/shared_settings.cfg
			sed -i "/confogl_addcvar\ sv_allow_lobby_connect_only\ 0/d" /home/louis/l4d2/left4dead2/cfg/cfgogl/*/shared_cvars.cfg
			sed -i "s/confogl_match_killlobbyres\ \ \ \ \ \ \ \ \ \ \"1\"/confogl_match_killlobbyres\ \ \ \ \ \ \ \ \ \ \"0\"/g" /home/louis/l4d2/left4dead2/cfg/cfgogl/*/shared_cvars.cfg
		fi
	fi
	
	if [ -n "$hidden" ]
	then	
		echo "\nsv_tags\ hidden" >> /home/louis/l4d2/left4dead2/cfg/server.cfg
	fi
	
	if [ -n "$serverid" ]
	then
		sed -i "47 s/\"2\"/\"$serverid\"/" /home/louis/l4d2/left4dead2/addons/sourcemod/configs/sourcebans/sourcebans.cfg
	fi
	
	#delete motd
	rm /home/louis/l4d2/left4dead2/*motd.txt
	rm /home/louis/l4d2/left4dead2/*host.txt
fi

# Start Game
cd l4d2 && ./srcds_run -console -game left4dead2 -ip 0.0.0.0 -tickrate 100 -port "$PORT"  +maxplayers "$PLAYERS" +map "$MAP" -secure
