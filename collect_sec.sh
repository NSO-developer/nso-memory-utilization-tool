#!/bin/bash

i=$1
PY_CHECK=$2
pid=$3
SUM_PHY=$4
SUM_ALO_PID=$5
Limit=$6
ALO_TOTAL=$7

ALO_PID=0
PHY=0

if [ $PY_CHECK -eq 1 ]; then
      name=$(ps -p $pid -o command | awk -F' ' '{print $9}')
    else
      name=$1
    fi
    name=$(echo $name)

    # ps -p $PID -o pid=,%mem=,rss= >> /tmp/mem.log
    TIME=$(date +%T)
    ALO_PID=$(pmap -d $pid | grep "writeable/private" | awk -F' ' '{print $4}' | egrep -o '[0-9.]+'  ) 
    PHY=$(cat /proc/$pid/status | grep VmRSS | awk -F' ' '{print $2}')
    echo $i" second is collected towards data/mem_"$name".log"
    echo $TIME" "$PHY" "$ALO_PID" "$ALO_TOTAL" "$Limit  >> "data/mem_$name.log"

    if [ $PY_CHECK -eq 1 ]; then
        re='^[0-9]+$'
        if [[ $ALO_PID =~ $re && $PHY =~ $re ]] ; then
          SUM_ALO_PID=$(($SUM_ALO_PID+$ALO_PID))
          SUM_PHY=$(($SUM_PHY+$PHY))
        fi
    fi