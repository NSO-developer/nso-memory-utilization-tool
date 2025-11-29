#!/bin/bash

NS=1000000000

PID=$1
OUTPUT_FILE=$2
DURATION=$3
VERBOSE=${4:-0}
SIGNAL_FILE=$5
SIGNALBACK_FILE="/tmp/signalback/nso_collect_start_signalback_$$"


if [ -z "$PID" ] || [ -z "$OUTPUT_FILE" ] || [ -z "$DURATION" ]; then
  echo "Usage: $0 <pid> <output_file> <duration> [verbose_flag] [signal_file]"
  exit 1
fi

log_verbose() {
  if [ $VERBOSE -eq 1 ]; then
    echo "$1"
  fi
}

if [[ $OUTPUT_FILE == *"python3"* ]]; then
PYTHON_SWITCH=1
else
PYTHON_SWITCH=0
fi


OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"



 
for (( i=0;i<=$DURATION;i++ ))
do
  
  # Wait for centralized controller signal
  if [ ! -z "$SIGNAL_FILE" ]; then
    log_verbose "Waiting for start signal..."
    #echo "Waiting for start signal..."
    while true; do
      if [ ! -f "$SIGNAL_FILE" ]; then
        sleep 0.1
      elif [[ $(cat $SIGNAL_FILE) -ne $i ]];then
        sleep 0.1
      else
        break
      fi
    done
    

    log_verbose "Start signal received. Beginning data collection for PID $PID..."
  fi
  rm -f $SIGNALBACK_FILE
  # Tick!
  ALO_TOTAL=$(cat /proc/meminfo | grep 'Committed_AS' | awk -F' ' '{print $2}')
  Limit=$(cat /proc/meminfo | grep 'CommitLimit' | awk -F' ' '{print $2}')

  TIME=$(date +%T)

  log_verbose "Monitoring PID: $PID"
  ALO_PID=$(pmap -d $PID | grep "writeable/private" | awk -F' ' '{print $4}' | egrep -o '[0-9.]+'  )
  PHY=$(cat /proc/$PID/status | grep VmRSS | awk -F' ' '{print $2}')

  if [ ! -z "$ALO_PID" ] && [ ! -z "$PHY" ]; then
    echo $TIME" "$PHY" "$ALO_PID" "$ALO_TOTAL" "$Limit  >> "$OUTPUT_FILE"
    log_verbose "$i second is collected to $OUTPUT_FILE"
  fi
  touch $SIGNALBACK_FILE


 done

log_verbose "Collection for PID $PID done"
