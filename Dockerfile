FROM debian:stable-slim AS install_system

RUN dpkg --add-architecture i386 && apt-get update
RUN apt-get install -y curl iputils-ping wget file tar bzip2 locales gzip unzip bsdmainutils python3 lib32z1 util-linux ca-certificates binutils bc jq tmux netcat-openbsd lib32gcc-s1 lib32stdc++6 git nano

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
	dpkg-reconfigure --frontend=noninteractive locales && \
	update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8 

RUN useradd -m louis
WORKDIR /home/louis
USER louis

FROM install_system AS install_game

# 安装 steamcmd 和 left 4 dead 2
RUN wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz && tar -xzf steamcmd_linux.tar.gz \
	&& rm steamcmd_linux.tar.gz && ./steamcmd.sh +quit
# Clean any previous SteamCMD files
RUN rm -rf /home/louis/Steam && ./steamcmd.sh +quit

# Step 1: Install Left 4 Dead 2 files
RUN ./steamcmd.sh +force_install_dir ./l4d2 +@sSteamCmdForcePlatformType windows +login anonymous +app_update 222860 validate +quit && ./steamcmd.sh +force_install_dir ./l4d2 +@sSteamCmdForcePlatformType linux +login anonymous +app_update 222860 validate +quit

RUN git clone --depth 1 -b zonemod https://github.com/fantasylidong/anne.git
RUN git clone --depth 1 https://github.com/fantasylidong/purecoop.git
RUN git clone --depth 1 -b mysql https://github.com/fantasylidong/neko.git
RUN git clone --depth 1 https://github.com/fantasylidong/100tickPureVersus.git
# 缓存期也拉取完整的仓库
RUN git clone https://github.com/fantasylidong/CompetitiveWithAnne.git

FROM install_game AS update

# 如果需要更新镜像，则构建时添加 --build-arg NEEDUPDATE=$(date +%s) 参数以消除后续缓存
# $(date +%s) 是获取当前时间戳，以保证唯一性
ARG NEEDUPDATE="no"
RUN ./steamcmd.sh +force_install_dir ./l4d2 +@sSteamCmdForcePlatformType linux +login anonymous +app_update 222860 validate +quit

RUN git -C anne pull --unshallow
RUN git -C purecoop pull --unshallow
RUN git -C neko pull --unshallow
RUN git -C 100tickPureVersus pull --unshallow
# 更新仓库
RUN git -C CompetitiveWithAnne pull

FROM update AS game

RUN rm -rf anne/left4dead2/addons/sourcemod/scripting/
RUN mkdir -p .steam/sdk32/ && ln -sf ~/linux32/steamclient.so ~/.steam/sdk32/steamclient.so \
	&& mkdir -p .steam/sdk64/ && ln -sf ~/linux64/steamclient.so ~/.steam/sdk64/steamclient.so

EXPOSE 27015/tcp
EXPOSE 27015/udp
VOLUME [ "/map", "/sm_configs" ]

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


COPY --chown=louis:louis ./entrypoints /home/louis/
ENTRYPOINT ["/bin/bash", "entrypoint.sh"]
