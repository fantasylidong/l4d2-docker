FROM debian

RUN dpkg --add-architecture i386 && apt-get update
RUN apt-get install -y curl iputils-ping wget file tar bzip2 locales gzip unzip bsdmainutils python3 lib32z1 util-linux ca-certificates binutils bc jq tmux netcat lib32gcc-s1 lib32stdc++6 git nano

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

#RUN echo "\n* soft core 0\n* hard core 0" >> /etc/security/limits.conf
#RUN echo "fs.suid_dumpable=0" >> /etc/sysctl.conf

ENV LANG en_US.UTF-8 

RUN useradd -m louis
WORKDIR /home/louis
USER louis

RUN wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz && tar -xzf steamcmd_linux.tar.gz \
    && rm steamcmd_linux.tar.gz && ./steamcmd.sh +quit
RUN mkdir -p .steam/sdk32/ && ln -s ~/linux32/steamclient.so ~/.steam/sdk32/steamclient.so \
    && mkdir -p .steam/sdk64/ && ln -s ~/linux64/steamclient.so ~/.steam/sdk64/steamclient.so
RUN ./steamcmd.sh +login anonymous +force_install_dir ./l4d2 +app_update 222860 +quit
RUN git clone -b zonemod https://github.com/fantasylidong/anne.git
RUN rm -rf anne/left4dead2/addons/sourcemod/scripting/
RUN git clone https://github.com/fantasylidong/purecoop.git
RUN git clone -b mysql https://github.com/fantasylidong/neko.git
RUN git clone https://github.com/fantasylidong/L4D2-Competitive-Rework.git
RUN git clone https://github.com/fantasylidong/100tickPureVersus.git

EXPOSE 27015/tcp
EXPOSE 27015/udp

ENV PORT=2333 \
    PLAYERS=8 \
    MAP="c2m1_highway" \
    REGION=255 \
    HOSTNAME="leo fighting" \
    plugin="null" \
	steamid="STEAM_1:1:121430603" \
	password="123456" \
	steamgroup="25622692,26419628" \
	stripper="false"

ADD entrypoint.sh entrypoint.sh
ENTRYPOINT ["sh", "entrypoint.sh"]
