if [ -n "$IP" ]; then
  cd l4d2 && ./srcds_run -console -game left4dead2 -ip "$IP" -tickrate 128 -port "$PORT" +maxplayers "$PLAYERS" +map "$MAP" +sv_setmax 31 -secure
else
  cd l4d2 && ./srcds_run -console -game left4dead2 -ip 0.0.0.0 -tickrate 128 -port "$PORT" +maxplayers "$PLAYERS" +map "$MAP" +sv_setmax 31 -secure
fi
