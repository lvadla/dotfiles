#!/usr/bin/env bash
for i in {1..5}
do
    text=$(curl -s "https://wttr.in/$1?format=%t")
    if [[ $? == 0 ]]
    then
        text=$(echo "$text" | sed -E "s/\s+//g" | sed -E "s/°C/C/g")
        tooltip=$(curl -s "https://wttr.in/$1?format=%l:+%c+%t+%C")
        if [[ $? == 0 ]]
        then
            tooltip=$(echo "$tooltip" | sed -E "s/\+/ /g" | sed -E "s/\s+/ /g")
            echo "{\"text\":\"$text\", \"tooltip\":\"$tooltip\"}"
            exit
        fi
    fi
    sleep 2
done
echo "{\"text\":\"error\", \"tooltip\":\"error\"}"
