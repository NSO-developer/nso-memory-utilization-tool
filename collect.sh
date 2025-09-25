#!/bin/bash


rm -rf data/$1
mkdir data/$1

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

NCS_CHECK=0
case "$1" in
     "ncs.smp")
        NCS_CHECK=1
        ;;
     *)
        NCS_CHECK=0
        ;;
    esac


for (( i=0;i<=$2;i++ ))
do
  #echo $i" second is collected"
  PID=$(pgrep -f $1)
  #PYfiles=$(ls data/python3)
  #UPDATEfiles=$(ps -o command -p $data | awk -F' ' '{print $9}')
  #Diff=$(comm <(echo $PYfiles) <(echo $UPDATEfiles))
  #if [ $PY_CHECK -eq 0 ]; then
  #  PID=$(echo $PID  | awk -F' ' '{print $1}')
  #fi

  ALO_TOTAL=$(cat /proc/meminfo | grep 'Committed_AS' | awk -F' ' '{print $2}')
  Limit=$(cat /proc/meminfo | grep 'CommitLimit' | awk -F' ' '{print $2}')

  SUM_ALO_PID=0
  SUM_PHY=0
  ALO_PID=0
  PHY=0
  TIME=$(date +%T)
  counter=$(wc -w <<< "$PID")

  for pid in $PID ; do
    name=""
    com=""
    if [ $PY_CHECK -eq 1 ]; then
      name=$(ps -p $pid -o command | awk -F' ' '{print $9}')
      com=name
    else
      name=$1
      com=$(ps -p $pid -o command | awk -F' ' '{print $5}')
      #echo $pid" "$name "  " $com " "$(ps -p $pid -o command)
    fi
    if [ ! -z "${name}" ] && [ ! -z "${com}" ]  ; then
      name=$(echo $name)
      echo "Monitoring PID: "$pid $name
      ALO_PID=$(pmap -d $pid | grep "writeable/private" | awk -F' ' '{print $4}' | egrep -o '[0-9.]+'  ) 
      PHY=$(cat /proc/$pid/status | grep VmRSS | awk -F' ' '{print $2}')

      if [ $PY_CHECK -eq 1 ] ||  [ $NCS_CHECK -eq 1 ] ; then
          re='^[0-9]+$'
          if [[ $ALO_PID =~ $re && $PHY =~ $re ]] ; then
            SUM_ALO_PID=$(($SUM_ALO_PID+$ALO_PID))
            SUM_PHY=$(($SUM_PHY+$PHY))
          fi
      fi
    fi
     if [ $counter -gt 1 ] ; then
        if [ ! -z "${name}" ]  && [ ! -z "${com}" ]   ; then
          if  [ $NCS_CHECK -eq 1 ] ; then
            echo $TIME" "$SUM_PHY" "$SUM_ALO_PID" "$ALO_TOTAL" "$Limit  >> "data/"$1"/mem_"$name".log"
            echo $i" second is collected towards data/"$1"/mem_"$name".log"
          else
            echo $TIME" "$PHY" "$ALO_PID" "$ALO_TOTAL" "$Limit  >> "data/"$1"/mem_"$name".log"
            echo $i" second is collected towards data/"$1"/mem_"$name".log"
          fi
        fi
     else
        if [ ! -z "${name}" ]  ; then
          echo $TIME" "$PHY" "$ALO_PID" "$ALO_TOTAL" "$Limit  >> "data/"$1"/mem_"$name".log"
          echo $i" second is collected towards data/"$1"/mem_"$name".log"
        fi
     fi
   done   

  if [ $PY_CHECK -eq 1 ]; then
    echo $TIME" "$SUM_PHY" "$SUM_ALO_PID" "$ALO_TOTAL" "$Limit  >> "data/"$1"/mem_total.log"  
  fi

  #echo $TIME" 0 0 0 0"  >> "data/ref.log"
  
  sleep 1
done

echo "Collection for "$1" done"
