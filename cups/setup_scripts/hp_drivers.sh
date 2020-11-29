#!/bin/bash

if [ -z HP_PLUGIN_URL ]; then
    HP_PLUGIN_URL="https://developers.hp.com/sites/default/files/hplip-3.18.12-plugin.run"
fi

LOCAL_PLUGIN="/tmp/hp-plugin.run"

echo "Downloading HP printer plugin..."
wget -O ${LOCAL_PLUGIN} ${HP_PLUGIN_URL}
wget -O ${LOCAL_PLUGIN}.asc ${HP_PLUGIN_URL}.asc
yes | hp-plugin -i -p ${LOCAL_PLUGIN}
