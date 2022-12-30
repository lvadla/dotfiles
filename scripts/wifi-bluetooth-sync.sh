#!/bin/bash

AIRPORT="en0"; #may be en0, use networksetup -listallhardwareports to check
WIFI_HOME_NETWORK_NAME="GNX0F92A4"
WIFI_WORK_NETWORK_NAME="pexip-sec"

echo 'System is waking.'
if networksetup -getairportnetwork $AIRPORT | grep -i -a $WIFI_HOME_NETWORK_NAME ; then
    blueutil -p 1
    echo 'Turning bluetooth on...'
    exit 0
elif networksetup -getairportnetwork $AIRPORT | grep -i -a $WIFI_WORK_NETWORK_NAME ; then
    blueutil -p 0
    echo 'Turning bluetooth off...'
    exit 0
else
    blueutil -p 0
    echo 'Turning bluetooth off...'
    exit 0
fi

exit 0;