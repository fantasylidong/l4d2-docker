#!/bin/bash
# Update Game
./steamcmd.sh +login anonymous +force_install_dir ./l4d2 +app_update 222860 +quit

#Softlink l4d2 maps to addons folder
#It would more convenience while you want add custom map. Exspecially when you have sourcemod plugins
#you just need mount your extra map folder to docker container /map . 
ln  -s  /map/*  l4d2/left4dead2/addons/

# plugins Config
if [ ! -d "/home/louis/l4d2/left4dead2/addons/sourcemod/" ];
then
	if [ "$plugin" = "anne" ];
	then
		cp  -r /home/louis/AnneServer/* l4d2/
		echo "anne plugins packge installed"
	fi
	
	if [ "$plugin" = "anne_old" ];
	then
		cp  -r /home/louis/anne_old/* l4d2/
		echo "anne_old plugins packge installed"
	fi

	if [ "$plugin" = "neko" ];
	then
		cp  -r /home/louis/neko/* l4d2/left4dead2/
		echo "neko plugins packge installed"
	fi

	if [ "$plugin" = "sirplease" ];
	then
		cp  -r /home/louis/L4D2-Competitive-Rework/* l4d2/left4dead2/
		echo "sirplease plugins packge installed"
	fi
	
	if [ "$plugin" = "hardneko" ];
	then
		cp  -r /home/louis/hardneko/* l4d2/left4dead2/
		echo "hardneko plugins packge installed"
	fi
	
	#plugins admin setting
	echo "\"$steamid\" \"99:z\"" >> /home/louis/l4d2/left4dead2/addons/sourcemod/configs/admins_simple.ini
	echo "hostname \"$HOSTNAME\"" >> /home/louis/l4d2/left4dead2/cfg/server.cfg
	echo "sv_steamgroup \"$steamgroup\"" >> /home/louis/l4d2/left4dead2/cfg/server.cfg
	echo "rcon_password \"$password\"" >> /home/louis/l4d2/left4dead2/cfg/server.cfg
fi

# Start Game
cd l4d2 && ./srcds_run -console -game left4dead2 -tickrate 100 -port "$PORT" +maxplayers "$PLAYERS" +map "$MAP"
