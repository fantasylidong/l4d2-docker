FROM debian:buster-slim

RUN dpkg --add-architecture i386 && apt-get update
RUN apt-get install -y curl iputils-ping wget file tar bzip2 locales gzip unzip bsdmainutils python3 lib32z1 util-linux ca-certificates binutils bc jq tmux netcat lib32gcc1 lib32stdc++6 git nano

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8 

RUN useradd -m louis
WORKDIR /home/louis
USER louis

# 安装 steamcmd 和 left 4 dead 2
RUN wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz && tar -xzf steamcmd_linux.tar.gz \
    && rm steamcmd_linux.tar.gz && ./steamcmd.sh +quit
RUN ./steamcmd.sh +force_install_dir ./l4d2 +login anonymous +app_update 222860 validate +quit

RUN mkdir -p .steam/sdk32/ && ln -s ~/linux32/steamclient.so ~/.steam/sdk32/steamclient.so \
    && mkdir -p .steam/sdk64/ && ln -s ~/linux64/steamclient.so ~/.steam/sdk64/steamclient.so

RUN git clone --depth 1 -b zonemod https://github.com/fantasylidong/anne.git
RUN rm -rf anne/left4dead2/addons/sourcemod/scripting/
RUN git clone --depth 1 https://github.com/fantasylidong/purecoop.git
RUN git clone --depth 1 -b mysql https://github.com/fantasylidong/neko.git
RUN git clone https://github.com/fantasylidong/CompetitiveWithAnne.git
RUN git clone --depth 1 https://github.com/fantasylidong/100tickPureVersus.git

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
	steamgroup="123456" \
	stripper="false" \
	steam64="" \
	mysql="" \
	mysqlport="" \
	mysqluser="" \
	mysqlpassword="" \
	dlurl=""

ADD entrypoint.sh entrypoint.sh
ENTRYPOINT ["sh", "entrypoint.sh"]
