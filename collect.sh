#!/bin/bash




PID=$(pgrep -f $1)
echo "Monitoring PID: "$PID

rm -f data/mem_*.log
#rm -f graphs/*

PY_CHECK=0

case "$1" in
     "python3") 
        PY_CHECK=1
        ;;

     "python") 
        PY_CHECK=1
        ;;
     *)
        PY_CHECK=0
        ;;
    esac





if [ $PY_CHECK -eq 0 ]; then
  PID=$(echo $PID  | awk -F' ' '{print $1}')
fi


for (( i=0;i<=$2;i++ ))
do
  #echo $i" second is collected"
  PID=$(pgrep -f $1)
  echo "Monitoring PID: "$PID
  if [ $PY_CHECK -eq 0 ]; then
    PID=$(echo $PID  | awk -F' ' '{print $1}')
  fi
  ALO_TOTAL=$(cat /proc/meminfo | grep 'Committed_AS' | awk -F' ' '{print $2}')
  Limit=$(cat /proc/meminfo | grep 'CommitLimit' | awk -F' ' '{print $2}')

  SUM_ALO_PID=0
  SUM_PHY=0
  ALO_PID=0
  PHY=0
  for pid in $PID ; do
    if [ $PY_CHECK -eq 1 ]; then
      name=$(ps -p $pid -o command | awk -F' ' '{print $9}')
    else
      name=$1
    fi
    name=$(echo $name)

    # ps -p $PID -o pid=,%mem=,rss= >> /tmp/mem.log
    ALO_PID=$(pmap -d $pid | grep "writeable/private" | awk -F' ' '{print $4}' | egrep -o '[0-9.]+'  ) 
    PHY=$(cat /proc/$pid/status | grep VmRSS | awk -F' ' '{print $2}')
    echo $i" second is collected towards data/mem_"$name".log"
    #echo $PHY" "$ALO_PID" "$ALO_TOTAL
    echo $PHY" "$ALO_PID" "$ALO_TOTAL" "$Limit  >> "data/mem_$name.log"

    if [ $PY_CHECK -eq 1 ]; then
        re='^[0-9]+$'
        if [[ $ALO_PID =~ $re && $PHY =~ $re ]] ; then
          SUM_ALO_PID=$(($SUM_ALO_PID+$ALO_PID))
          SUM_PHY=$(($SUM_PHY+$PHY))
        fi
    fi

  done   

  if [ $PY_CHECK -eq 1 ]; then
    echo $SUM_PHY" "$SUM_ALO_PID" "$ALO_TOTAL" "$Limit  >> "data/mem_total.log"  
  fi
  
  sleep 1
done



echo "Collection for "$name" done"
