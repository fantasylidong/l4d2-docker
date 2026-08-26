# syntax=docker/dockerfile:1.7

ARG IMAGE_PLATFORM=linux/amd64
ARG L4D2_SOURCE_IMAGE=morzlee/l4d2:latest

FROM --platform=$IMAGE_PLATFORM debian:stable-slim AS runtime_system

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        git \
        inotify-tools \
        lib32gcc-s1 \
        lib32stdc++6 \
        lib32z1 \
        nano \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/*

RUN useradd -m louis
WORKDIR /home/louis
USER louis

FROM runtime_system AS build_system

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bzip2 \
        gzip \
        tar \
        wget \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/*
USER louis

FROM build_system AS install_steamcmd

RUN wget -q -O steamcmd_linux.tar.gz http://media.steampowered.com/installer/steamcmd_linux.tar.gz \
    && tar -xzf steamcmd_linux.tar.gz \
    && rm steamcmd_linux.tar.gz

FROM install_steamcmd AS steamcmd_runtime

RUN mkdir -p /home/louis/steamcmd-runtime \
    && cp -a /home/louis/steamcmd.sh /home/louis/steam.sh /home/louis/steamcmd-runtime/ \
    && for path in .steam Steam linux32 linux64 package public steamapps config servers; do \
        if [ -e "/home/louis/$path" ]; then cp -a "/home/louis/$path" /home/louis/steamcmd-runtime/; fi; \
    done \
    && rm -rf \
        /home/louis/steamcmd-runtime/.steam/root/logs \
        /home/louis/steamcmd-runtime/Steam/logs

FROM install_steamcmd AS install_game

ARG NEEDUPDATE="no"
RUN echo "$NEEDUPDATE" >/tmp/needupdate-steam \
    && ./steamcmd.sh +force_install_dir ./l4d2 +@sSteamCmdForcePlatformType linux +login anonymous +app_update 222860 validate +quit \
    && rm -rf \
        /home/louis/.steam/root/appcache \
        /home/louis/.steam/root/config \
        /home/louis/.steam/root/logs \
        /home/louis/.steam/root/package \
        /home/louis/.steam/root/public \
        /home/louis/.steam/root/steamapps \
        /home/louis/.steam/root/ubuntu12_32 \
        /home/louis/.steam/root/ubuntu12_64 \
        /home/louis/Steam \
        /home/louis/l4d2/steamapps/downloading \
        /home/louis/l4d2/steamapps/temp \
        /tmp/needupdate-steam

FROM install_game AS game_files

RUN mkdir -p /home/louis/runtime-home \
    && cp -R /home/louis/l4d2 /home/louis/runtime-home/l4d2 \
    && if [ -d /home/louis/linux32 ]; then cp -R /home/louis/linux32 /home/louis/runtime-home/linux32; fi \
    && if [ -d /home/louis/linux64 ]; then cp -R /home/louis/linux64 /home/louis/runtime-home/linux64; fi

FROM runtime_system AS install_game_local

COPY --chown=louis:louis --from=l4d2_server . /home/louis/l4d2/

RUN mkdir -p /home/louis/l4d2/steamapps \
    && test -d /home/louis/l4d2/left4dead2 \
    && test -f /home/louis/l4d2/srcds_run \
    && (test -f /home/louis/l4d2/bin/steamclient.so || \
        echo 'warning: bin/steamclient.so not found; server startup may need linux32/steamclient.so') \
    && (test -f /home/louis/l4d2/steamapps/appmanifest_222860.acf || \
        echo 'warning: steamapps/appmanifest_222860.acf not found; SteamCMD validate/update may redownload files later') \
    && mkdir -p /home/louis/runtime-home \
    && cp -R /home/louis/l4d2 /home/louis/runtime-home/l4d2

FROM --platform=$IMAGE_PLATFORM ${L4D2_SOURCE_IMAGE} AS l4d2_source_image

FROM runtime_system AS install_game_image

RUN --mount=from=l4d2_source_image,source=/home/louis,target=/source,readonly \
    cp -R /source/l4d2 /home/louis/l4d2 \
    && if [ -d /source/linux32 ]; then cp -R /source/linux32 /home/louis/linux32; fi \
    && if [ -d /source/linux64 ]; then cp -R /source/linux64 /home/louis/linux64; fi

RUN test -d /home/louis/l4d2/left4dead2 \
    && test -f /home/louis/l4d2/srcds_run \
    && (test -f /home/louis/l4d2/steamapps/appmanifest_222860.acf || \
        echo 'warning: steamapps/appmanifest_222860.acf not found in source image') \
    && mkdir -p /home/louis/runtime-home \
    && cp -R /home/louis/l4d2 /home/louis/runtime-home/l4d2 \
    && if [ -d /home/louis/linux32 ]; then cp -R /home/louis/linux32 /home/louis/runtime-home/linux32; fi \
    && if [ -d /home/louis/linux64 ]; then cp -R /home/louis/linux64 /home/louis/runtime-home/linux64; fi

FROM build_system AS plugin_sources

ARG NEEDUPDATE="no"
RUN echo "$NEEDUPDATE" >/tmp/needupdate-plugins \
    && git clone --depth 1 -b zonemod https://github.com/fantasylidong/anne.git /tmp/anne \
    && git clone --depth 1 https://github.com/fantasylidong/CompetitiveWithAnne.git /home/louis/CompetitiveWithAnne \
    && mkdir -p /home/louis/CompetitiveWithAnne/maps/anne_nav \
    && cd /tmp/anne/update/maps \
    && find . -type f -name '*.nav' -exec cp --parents -t /home/louis/CompetitiveWithAnne/maps/anne_nav/ {} + \
    && test -n "$(find /home/louis/CompetitiveWithAnne/maps/anne_nav -type f -name '*.nav' -print -quit)" \
    && printf '\n/maps/anne_nav/\n' >> /home/louis/CompetitiveWithAnne/.git/info/exclude \
    && mkdir -p /home/louis/anne/left4dead2 \
    && cp -a /tmp/anne/left4dead2/sound /tmp/anne/left4dead2/models /tmp/anne/left4dead2/materials /home/louis/anne/left4dead2/ \
    && test -d /home/louis/anne/left4dead2/sound \
    && test -d /home/louis/anne/left4dead2/models \
    && test -d /home/louis/anne/left4dead2/materials \
    && rm -rf /tmp/anne /tmp/needupdate-plugins

FROM runtime_system AS runtime_common

COPY --chown=louis:louis --from=steamcmd_runtime /home/louis/steamcmd-runtime/ /home/louis/
COPY --chown=louis:louis --from=plugin_sources /home/louis/CompetitiveWithAnne /home/louis/CompetitiveWithAnne
COPY --chown=louis:louis --from=plugin_sources /home/louis/anne /home/louis/anne
COPY --chown=louis:louis ./entrypoints /home/louis/

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

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]

FROM runtime_common AS game

COPY --chown=louis:louis --from=game_files /home/louis/runtime-home/ /home/louis/
RUN mkdir -p /home/louis/.steam/sdk32/ /home/louis/.steam/sdk64/ \
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

FROM runtime_common AS game_local

COPY --chown=louis:louis --from=install_game_local /home/louis/runtime-home/ /home/louis/
RUN mkdir -p /home/louis/.steam/sdk32/ /home/louis/.steam/sdk64/ \
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

FROM runtime_common AS game_from_image

COPY --chown=louis:louis --from=install_game_image /home/louis/runtime-home/ /home/louis/
RUN mkdir -p /home/louis/.steam/sdk32/ /home/louis/.steam/sdk64/ \
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

FROM game AS final
