echo "Launching ioquake3 server..."

if [ -z ${SERVER_ARGS} ]; then
    echo "No additional server arguments found; running default Team Deathmatch configuration."
    SERVER_ARGS="+exec configs/tdm.cfg"
fi

if [ -z ${ADMIN_PASSWORD} ]; then
    ADMIN_PASSWORD=$(cat /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32})
    echo "No admin password set; defaulting to ${ADMIN_PASSWORD}."
fi

/usr/local/games/quake3/ioq3ded +seta rconPassword "${ADMIN_PASSWORD}" +exec configs/common.cfg ${SERVER_ARGS}