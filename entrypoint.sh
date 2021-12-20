#!/bin/bash
# Update Game
./steamcmd.sh +login anonymous +force_install_dir ./l4d2 +app_update 222860 +quit

#Softlink l4d2 maps to addons folder
#It would more convenience while you want add custom map. Exspecially when you have sourcemod plugins
#you just need mount your extra map folder to docker container /map . 
ln  -s  /map/*  l4d2/left4dead2/addons/

# plugins Config
#!/bin/bash 
if [ "$plugin" = "anne" ]
then
    cp -v -r /home/louis/AnneServer/* l4d2/
fi

if [ "$plugin" = "neko" ]
then
    cp -v -r /home/louis/neko/* l4d2/
fi

if [ "$plugin" = "sirplease" ]
then
    cp -v -r /home/louis/L4D2-Competitive-Rework/* l4d2/left4dead2/
fi

#plugins admin setting
echo "\"$steamid\" \"99:z\"" >> /home/louis/l4d2/left4dead2/addons/sourcemod/configs/admins_simple.ini

# Start Game
cd l4d2 && ./srcds_run -console -game left4dead2 -tickrate 100 -port "$PORT" +maxplayers "$PLAYERS" +map "$MAP"
