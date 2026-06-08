ARG IMAGE_PLATFORM=linux/amd64
ARG L4D2_SOURCE_IMAGE=morzlee/l4d2:latest
FROM --platform=$IMAGE_PLATFORM debian:stable-slim AS install_system

RUN dpkg --add-architecture i386 && apt-get update
RUN apt-get install -y curl iputils-ping wget file tar bzip2 locales gzip unzip bsdmainutils python3 lib32z1 util-linux ca-certificates binutils bc jq tmux netcat-openbsd lib32gcc-s1 lib32stdc++6 git nano \
    && apt-get install -y inotify-tools  # <-- 新增：安装 inotify-tools

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8

RUN useradd -m louis
WORKDIR /home/louis
USER louis

FROM install_system AS install_steamcmd

# 安装 steamcmd
RUN wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz && tar -xzf steamcmd_linux.tar.gz \
    && rm steamcmd_linux.tar.gz && ./steamcmd.sh +quit
# Clean any previous SteamCMD files
RUN rm -rf /home/louis/Steam && ./steamcmd.sh +quit

FROM install_steamcmd AS install_game

# Step 1: Install Left 4 Dead 2 files
RUN ./steamcmd.sh +force_install_dir ./l4d2 +@sSteamCmdForcePlatformType linux +login anonymous +app_update 222860 validate +quit

FROM install_system AS install_game_local

COPY --chown=louis:louis --from=l4d2_server . /home/louis/l4d2/

RUN mkdir -p /home/louis/l4d2/steamapps \
    && test -d /home/louis/l4d2/left4dead2 \
    && test -f /home/louis/l4d2/srcds_run \
    && (test -f /home/louis/l4d2/bin/steamclient.so || \
        echo 'warning: bin/steamclient.so not found; server startup may need SteamCMD linux32/steamclient.so') \
    && (test -f /home/louis/l4d2/steamapps/appmanifest_222860.acf || \
        echo 'warning: steamapps/appmanifest_222860.acf not found; SteamCMD validate/update may redownload files later')

FROM --platform=$IMAGE_PLATFORM ${L4D2_SOURCE_IMAGE} AS l4d2_source_image

FROM install_system AS install_game_image

RUN --mount=from=l4d2_source_image,source=/home/louis,target=/source,readonly \
    cp -R /source/l4d2 /home/louis/l4d2 \
    && if [ -d /source/linux32 ]; then cp -R /source/linux32 /home/louis/linux32; fi \
    && if [ -d /source/linux64 ]; then cp -R /source/linux64 /home/louis/linux64; fi

RUN test -d /home/louis/l4d2/left4dead2 \
    && test -f /home/louis/l4d2/srcds_run \
    && (test -f /home/louis/l4d2/steamapps/appmanifest_222860.acf || \
        echo 'warning: steamapps/appmanifest_222860.acf not found in source image')

FROM install_game AS install_plugins

RUN git clone --depth 1 -b zonemod https://github.com/fantasylidong/anne.git
#RUN git clone --depth 1 https://github.com/fantasylidong/purecoop.git
#RUN git clone --depth 1 -b mysql https://github.com/fantasylidong/neko.git
#RUN git clone --depth 1 https://github.com/fantasylidong/100tickPureVersus.git
# 缓存期也拉取完整的仓库
RUN git clone https://github.com/fantasylidong/CompetitiveWithAnne.git

FROM install_game_local AS install_plugins_local

RUN git clone --depth 1 -b zonemod https://github.com/fantasylidong/anne.git
#RUN git clone --depth 1 https://github.com/fantasylidong/purecoop.git
#RUN git clone --depth 1 -b mysql https://github.com/fantasylidong/neko.git
#RUN git clone --depth 1 https://github.com/fantasylidong/100tickPureVersus.git
# 缓存期也拉取完整的仓库
RUN git clone https://github.com/fantasylidong/CompetitiveWithAnne.git

FROM install_game_image AS install_plugins_image

RUN git clone --depth 1 -b zonemod https://github.com/fantasylidong/anne.git
#RUN git clone --depth 1 https://github.com/fantasylidong/purecoop.git
#RUN git clone --depth 1 -b mysql https://github.com/fantasylidong/neko.git
#RUN git clone --depth 1 https://github.com/fantasylidong/100tickPureVersus.git
# 缓存期也拉取完整的仓库
RUN git clone https://github.com/fantasylidong/CompetitiveWithAnne.git

FROM install_plugins AS update

# 如果需要更新镜像，则构建时添加 --build-arg NEEDUPDATE=$(date +%s) 参数以消除后续缓存
# $(date +%s) 是获取当前时间戳，以保证唯一性
ARG NEEDUPDATE="no"
RUN ./steamcmd.sh +force_install_dir ./l4d2 +@sSteamCmdForcePlatformType linux +login anonymous +app_update 222860 validate +quit

RUN git -C anne pull --unshallow
# 更新仓库
RUN git -C CompetitiveWithAnne pull

FROM install_plugins_local AS update_local

# 本地文件构建路径不执行 SteamCMD。更新服务端文件时，请先在宿主机更新 l4d2_server 目录后重新构建。
ARG NEEDUPDATE="no"
RUN test -n "$NEEDUPDATE"

RUN git -C anne pull --unshallow
# 更新仓库
RUN git -C CompetitiveWithAnne pull

FROM install_plugins_image AS update_image

# 从已有镜像复制游戏文件时不执行 SteamCMD；更新游戏文件请先更新 L4D2_SOURCE_IMAGE。
ARG NEEDUPDATE="no"
RUN test -n "$NEEDUPDATE"

RUN git -C anne pull --unshallow
# 更新仓库
RUN git -C CompetitiveWithAnne pull

FROM update AS runtime_common

# 清理 scripting 目录（保持你的原逻辑）
RUN rm -rf anne/left4dead2/addons/sourcemod/scripting/
RUN mkdir -p .steam/sdk32/ .steam/sdk64/ \
    && if [ -f /home/louis/linux32/steamclient.so ]; then \
        ln -sf /home/louis/linux32/steamclient.so /home/louis/.steam/sdk32/steamclient.so; \
    elif [ -f /home/louis/l4d2/bin/steamclient.so ]; then \
        ln -sf /home/louis/l4d2/bin/steamclient.so /home/louis/.steam/sdk32/steamclient.so; \
    else \
        echo 'warning: no 32-bit steamclient.so found for ~/.steam/sdk32'; \
    fi \
    && if [ -f /home/louis/linux64/steamclient.so ]; then \
        ln -sf /home/louis/linux64/steamclient.so /home/louis/.steam/sdk64/steamclient.so; \
    elif [ -f /home/louis/l4d2/bin/linux64/steamclient.so ]; then \
        ln -sf /home/louis/l4d2/bin/linux64/steamclient.so /home/louis/.steam/sdk64/steamclient.so; \
    else \
        echo 'warning: no 64-bit steamclient.so found for ~/.steam/sdk64'; \
    fi

# --- 新增：放置监听脚本，并赋可执行权限（仍然在用户 louis 下） ---
USER root
COPY --chown=root:root link_watcher.sh /usr/local/bin/link_watcher.sh
RUN chmod +x /usr/local/bin/link_watcher.sh
USER louis
# ---------------------------------------------------------------

EXPOSE 27015/tcp
EXPOSE 27015/udp
VOLUME [ "/map", "/sm_configs" ]

ENV PORT=2333 \
	PLAYERS=31 \
	MAP="c2m1_highway" \
	REGION=255 \
	HOSTNAME="leo fighting" \
	plugin="null" \
	steamid="STEAM_1:1:121430603" \
	steamgroup="123456" \
	stripper="false" \
	steam64="" \
	mysql="" \
	mysqlport="" \
	mysqluser="" \
	dlurl=""


COPY --chown=louis:louis ./entrypoints /home/louis/
ENTRYPOINT ["/bin/bash", "entrypoint.sh"]

FROM runtime_common AS game

FROM update_local AS game_local

RUN rm -rf anne/left4dead2/addons/sourcemod/scripting/
RUN mkdir -p .steam/sdk32/ .steam/sdk64/ \
    && if [ -f /home/louis/linux32/steamclient.so ]; then \
        ln -sf /home/louis/linux32/steamclient.so /home/louis/.steam/sdk32/steamclient.so; \
    elif [ -f /home/louis/l4d2/bin/steamclient.so ]; then \
        ln -sf /home/louis/l4d2/bin/steamclient.so /home/louis/.steam/sdk32/steamclient.so; \
    else \
        echo 'warning: no 32-bit steamclient.so found for ~/.steam/sdk32'; \
    fi \
    && if [ -f /home/louis/linux64/steamclient.so ]; then \
        ln -sf /home/louis/linux64/steamclient.so /home/louis/.steam/sdk64/steamclient.so; \
    elif [ -f /home/louis/l4d2/bin/linux64/steamclient.so ]; then \
        ln -sf /home/louis/l4d2/bin/linux64/steamclient.so /home/louis/.steam/sdk64/steamclient.so; \
    else \
        echo 'warning: no 64-bit steamclient.so found for ~/.steam/sdk64'; \
    fi

USER root
COPY --chown=root:root link_watcher.sh /usr/local/bin/link_watcher.sh
RUN chmod +x /usr/local/bin/link_watcher.sh
USER louis

EXPOSE 27015/tcp
EXPOSE 27015/udp
VOLUME [ "/map", "/sm_configs" ]

ENV PORT=2333 \
	PLAYERS=31 \
	MAP="c2m1_highway" \
	REGION=255 \
	HOSTNAME="leo fighting" \
	plugin="null" \
	steamid="STEAM_1:1:121430603" \
	steamgroup="123456" \
	stripper="false" \
	steam64="" \
	mysql="" \
	mysqlport="" \
	mysqluser="" \
	dlurl=""

COPY --chown=louis:louis ./entrypoints /home/louis/
ENTRYPOINT ["/bin/bash", "entrypoint.sh"]

FROM update_image AS game_from_image

RUN rm -rf anne/left4dead2/addons/sourcemod/scripting/
RUN mkdir -p .steam/sdk32/ .steam/sdk64/ \
    && if [ -f /home/louis/linux32/steamclient.so ]; then \
        ln -sf /home/louis/linux32/steamclient.so /home/louis/.steam/sdk32/steamclient.so; \
    elif [ -f /home/louis/l4d2/bin/steamclient.so ]; then \
        ln -sf /home/louis/l4d2/bin/steamclient.so /home/louis/.steam/sdk32/steamclient.so; \
    else \
        echo 'warning: no 32-bit steamclient.so found for ~/.steam/sdk32'; \
    fi \
    && if [ -f /home/louis/linux64/steamclient.so ]; then \
        ln -sf /home/louis/linux64/steamclient.so /home/louis/.steam/sdk64/steamclient.so; \
    elif [ -f /home/louis/l4d2/bin/linux64/steamclient.so ]; then \
        ln -sf /home/louis/l4d2/bin/linux64/steamclient.so /home/louis/.steam/sdk64/steamclient.so; \
    else \
        echo 'warning: no 64-bit steamclient.so found for ~/.steam/sdk64'; \
    fi

USER root
COPY --chown=root:root link_watcher.sh /usr/local/bin/link_watcher.sh
RUN chmod +x /usr/local/bin/link_watcher.sh
USER louis

EXPOSE 27015/tcp
EXPOSE 27015/udp
VOLUME [ "/map", "/sm_configs" ]

ENV PORT=2333 \
	PLAYERS=31 \
	MAP="c2m1_highway" \
	REGION=255 \
	HOSTNAME="leo fighting" \
	plugin="null" \
	steamid="STEAM_1:1:121430603" \
	steamgroup="123456" \
	stripper="false" \
	steam64="" \
	mysql="" \
	mysqlport="" \
	mysqluser="" \
	dlurl=""

COPY --chown=louis:louis ./entrypoints /home/louis/
ENTRYPOINT ["/bin/bash", "entrypoint.sh"]

FROM game AS final
