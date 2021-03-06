#!/bin/bash
LAT_V="$(curl -v --silent  https://www.minecraft.net/en-us/download/server/bedrock/ 2>&1 | \
	grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*' | \
    sed 's#.*/bedrock-server-##' | sed 's/.zip//')"
INS_V="$(find ${SERVER_DIR} -name *.installed | cut -d '-' -f 3 | awk -F ".installed" '{print $1}')"
if [ "${GAME_VERSION}" == "latest" ]; then
	GAME_VERSION=$LAT_V
fi
echo "---Setting umask to ${UMASK}---"
umask ${UMASK}

if [ -z "$INS_V" ]; then
	echo "---Minecraft Bedrock not found, Downloading v${GAME_VERSION}---"
	cd ${SERVER_DIR}
	if wget -q -nc --show-progress --progress=bar:force:noscroll https://minecraft.azureedge.net/bin-linux/bedrock-server-${GAME_VERSION}.zip ; then
		echo "---Successfully downloaded Minecraft Bedrock Edition!---"
	else
		echo "---Something went wrong, can't download Minecraft Bedrock Edition, putting server in sleep mode---"
		sleep infinity
	fi
    sleep 2
    if [ ! -s ${SERVER_DIR}/bedrock-server-${GAME_VERSION}.zip ]; then
    	echo "---You probably entered a wrong version number the server zip is empty---"
        rm bedrock-server-${GAME_VERSION}.zip
        sleep infinity
    fi
    unzip -o bedrock-server-${GAME_VERSION}.zip
    rm bedrock-server-${GAME_VERSION}.zip
    touch bedrock-server-${GAME_VERSION}.installed
    mv ${SERVER_DIR}/server.properties ${SERVER_DIR}/vanilla.server.properties
elif [ "${GAME_VERSION}" != "$INS_V" ]; then
	echo "---Version missmatch Installed: v$INS_V - Prefered:${GAME_VERSION}, downloading v${GAME_VERSION}---"
	cd ${SERVER_DIR}
	if wget -q -nc --show-progress --progress=bar:force:noscroll https://minecraft.azureedge.net/bin-linux/bedrock-server-${GAME_VERSION}.zip ; then
		echo "---Successfully downloaded Minecraft Bedrock Edition!---"
	else
		echo "---Something went wrong, can't download Minecraft Bedrock Edition, putting server in sleep mode---"
		sleep infinity
	fi
    sleep 2
    if [ ! -s ${SERVER_DIR}/bedrock-server-${GAME_VERSION}.zip ]; then
    	echo "---You probably entered a wrong version number the server zip is empty---"
        rm bedrock-server-${GAME_VERSION}.zip
        sleep infinity
    fi
    echo "---Creating Backup of config files---"
    mkdir ${SERVER_DIR}/backup_config_files
    mv ${SERVER_DIR}/server.properties ${SERVER_DIR}/backup_config_files/server.properties
    mv ${SERVER_DIR}/permissions.json ${SERVER_DIR}/backup_config_files/permissions.json
    mv ${SERVER_DIR}/whitelist.json ${SERVER_DIR}/backup_config_files/whitelist.json
    echo "---Installing v${GAME_VERSION}---"
	unzip -o bedrock-server-${GAME_VERSION}.zip
	rm bedrock-server-${GAME_VERSION}.zip
    mv ${SERVER_DIR}/server.properties ${SERVER_DIR}/vanilla.server.properties
    echo "---Copying Backup config files back to server directory---"
    mv ${SERVER_DIR}/backup_config_files/server.properties ${SERVER_DIR}/server.properties
    mv ${SERVER_DIR}/backup_config_files/permissions.json ${SERVER_DIR}/permissions.json
    mv ${SERVER_DIR}/backup_config_files/whitelist.json ${SERVER_DIR}/whitelist.json
    rm -R ${SERVER_DIR}/backup_config_files
    rm ${SERVER_DIR}/bedrock-server-$INS_V.installed
	touch bedrock-server-${GAME_VERSION}.installed
elif [ "${GAME_VERSION}" == "$INS_V" ]; then
	echo "---Minecraft Bedrock Server Version up-to-date---"
else
	echo "---Something went wrong, putting server in sleep mode---"
	sleep infinity
fi

echo "---Preparing Server---"
chmod -R 777 ${DATA_DIR}
echo "---Checking for 'server.properties'---"
if [ ! -f ${SERVER_DIR}/server.properties ]; then
    echo "---No 'server.properties' found, downloading...---"
	cd ${SERVER_DIR}
    if wget -q -nc --show-progress --progress=bar:force:noscroll https://raw.githubusercontent.com/ich777/docker-minecraft-bedrock/master/config/server.properties ; then
		echo "---Successfully downloaded 'server.properties'---"
	else
		echo "---Something went wrong, can't download 'server.properties', putting server in sleep mode---"
	sleep infinity
	fi
    sleep 2
else
    echo "---'server.properties' found..."
fi
echo "---Checking for old logs---"
find ${SERVER_DIR} -name "masterLog.*" -exec rm -f {} \;

echo "---Starting Server---"
cd ${SERVER_DIR}
LD_LIBRARY_PATH=. && screen -S Minecraft -L -Logfile ${SERVER_DIR}/masterLog.0 -d -m ${SERVER_DIR}/bedrock_server ${GAME_PARAMS}
sleep 2
tail -f ${SERVER_DIR}/masterLog.0