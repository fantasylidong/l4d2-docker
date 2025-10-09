if [ -n "$IP" ]; then
  cd l4d2 && ./srcds_run -console -game left4dead2 -ip "$IP" -tickrate 128 -port "$PORT" +maxplayers 31 +map "$MAP" -secure
else
  cd l4d2 && ./srcds_run -console -game left4dead2 -ip 0.0.0.0 -tickrate 128 -port "$PORT" +maxplayers 31 +map "$MAP" -secure
fi
