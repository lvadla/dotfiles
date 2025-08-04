#!/bin/bash

uptime_seconds=$(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1)

days=$((uptime_seconds / 86400))
hours=$(((uptime_seconds % 86400) / 3600))
minutes=$(((uptime_seconds % 3600) / 60))

if [ $days -gt 0 ]; then
    echo "${days}d ${hours}h ${minutes}m"
elif [ $hours -gt 0 ]; then
    echo "${hours}h ${minutes}m"
else
    echo "${minutes}m"
fi
