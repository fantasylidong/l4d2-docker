#!/bin/bash
# Update Game
./steamcmd.sh +login anonymous +force_install_dir ./l4d2 +app_update 222860 +quit

#Softlink l4d2 maps to addons folder
#It would more convenience while you want add custom map. Exspecially when you have sourcemod plugins
#you just need mount your extra map folder to docker container /map . 
ln  -s  /map/*  l4d2/left4dead2/addons/
ln  -s  /map2/*  l4d2/left4dead2/addons/
oldpluginpackage(){
	echo "\"$steamid\" \"100:z\"" >> /home/louis/l4d2/left4dead2/addons/sourcemod/configs/admins_simple.ini
	echo "sv_steamgroup \"$steamgroup\"" >> /home/louis/l4d2/left4dead2/cfg/server.cfg
	echo "rcon_password \"$password\"" >> /home/louis/l4d2/left4dead2/cfg/server.cfg
}
newpluginpackage(){
	sed -i 's/13333337/$steamgroup/g' >> /home/louis/l4d2/left4dead2/cfg/server.cfg
	sed -i 's/CompetitiveRework/annehappy/g' >> /home/louis/l4d2/left4dead2/cfg/server.cfg
	sed -i 's/WowYouKnowThePasswordHere/$password/g' >> /home/louis/l4d2/left4dead2/cfg/server.cfg
}
cloudconfig(){
	#cloud server settings
	sed -i 's/nb_update_frequency\ 0.014/nb_update_frequency\ 0.03/' /home/louis/l4d2/left4dead2/cfg/networkconfig.cfg
	sed -i 's/fps_max\ 150/fps_max\ 0/' /home/louis/l4d2/left4dead2/cfg/server.cfg
	sed -i '47 s/\"2\"/\"16\"/' /home/louis/l4d2/left4dead2/addons/sourcemod/configs/sourcebans/sourcebans.cfg
	cp /home/louis/l4d2/left4dead2/addons/hostname.txt /home/louis/l4d2/left4dead2/addons/sourcemod/configs/hostname/
	cp /home/louis/l4d2/left4dead2/addons/advertisements.txt /home/louis/l4d2/left4dead2/addons/sourcemod/configs/advertisements.txt
	cp /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/disabled/specrates.smx /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/optional/ 
}

localconfig(){
	if [ "$PORT" = "2330" ];
	then
		rm /home/louis/l4d2/left4dead2/addons/sourcemod/plugins/optional/sam_vs.smx
	fi
	if [ "$PORT" = "2340" ];
	then
		sed -i 's/AnneHappy6.cfg/AnneHappy4.cfg/g' /home/louis/l4d2/left4dead2/cfg/cfgogl/AnneHappy/confogl_plugins.cfg
		echo "sm_cvar ai_Tank_StopDistance 145" >> /home/louis/l4d2/left4dead2/cfg/cfgogl/AnneHappy/confogl_plugins.cfg
		echo "sm_cvar ai_TankAirAngleRestrict 60" >> /home/louis/l4d2/left4dead2/cfg/cfgogl/AnneHappy/confogl_plugins.cfg
	fi
	if [ "$PORT" = "2341" ];
	then
		sed -i 's/AnneHappy6.cfg/AnneHappy5.cfg/g' /home/louis/l4d2/left4dead2/cfg/cfgogl/AnneHappy/confogl_plugins.cfg
		echo "sm_cvar ai_Tank_StopDistance 140" >> /home/louis/l4d2/left4dead2/cfg/cfgogl/AnneHappy/confogl_plugins.cfg
		echo "sm_cvar ai_TankAirAngleRestrict 60" >> /home/louis/l4d2/left4dead2/cfg/cfgogl/AnneHappy/confogl_plugins.cfg
	fi
	if [ "$PORT" = "2342" ];
	then
		sed -i 's/AnneHappy6.cfg/AnneHappy6.cfg/g' /home/louis/l4d2/left4dead2/cfg/cfgogl/AnneHappy/confogl_plugins.cfg
		echo "sm_cvar ai_Tank_StopDistance 135" >> /home/louis/l4d2/left4dead2/cfg/cfgogl/AnneHappy/confogl_plugins.cfg
		echo "sm_cvar ai_TankAirAngleRestrict 60" >> /home/louis/l4d2/left4dead2/cfg/cfgogl/AnneHappy/confogl_plugins.cfg
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

	if [ "$plugin" = "angel" ];
	then
		cp  -r /home/louis/AngelBeats/* l4d2/left4dead2/
		echo "AngelBeats plugins packge installed"
		oldpluginpackage
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
		echo "neko plugins packge installed"
		oldpluginpackage
	fi
	
	if [ "$plugin" = "zone" ];
	then
		cp  -r /home/louis/CompetitiveWithAnne/* l4d2/left4dead2/
		# nav file copy
		cp -r /home/louis/anne/update/* l4d2/
		cp -r /home/louis/anne/left4dead2/sound/ l4d2/left4dead2/
		cp -r /home/louis/anne/left4dead2/model/ l4d2/left4dead2/
		echo "zone plugins packge installed"
		localconfig
		newpluginpackage
	fi
	
	if [ "$plugin" = "pureversus" ];
	then
		cp  -r /home/louis/100tickPureVersus/* l4d2/left4dead2/
		if [ "$PORT" = "2353" ];
		then
			sed -i 's/mutation12/versus/g' /home/louis/l4d2/left4dead2/cfg/server.cfg
		fi
		echo "pure versus packge installed"
	fi
	
	if [ "$cloud" = "true" ];
	then
		#localserver change to static local ip
		sed -i 's/home.trygek.com/10.0.0.4/g' /home/louis/l4d2/left4dead2/addons/sourcemod/configs/databases.cfg
		sed -i 's/12345/3306/g' /home/louis/l4d2/left4dead2/addons/sourcemod/configs/databases.cfg
	fi
	
	#plugins admin setting
	echo "sv_region \"$REGION\"" >> /home/louis/l4d2/left4dead2/cfg/server.cfg
	
	#delete motd
	rm /home/louis/l4d2/left4dead2/*motd.txt
fi

# Start Game
cd l4d2 && ./srcds_run -console -game left4dead2 -ip 0.0.0.0 -tickrate 100 -port "$PORT"  +maxplayers "$PLAYERS" +map "$MAP"
