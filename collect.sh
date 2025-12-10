#!/bin/bash

NS=1000000000


SCRIPT_NAME=$1
PID=$(pgrep -f "$SCRIPT_NAME")
OUTPUT_FILE=$2
DURATION=$3
VERBOSE=${4:-0}
SIGNAL_FILE=$5
STARTI=$6
CACHE_FILE="/tmp/cache.log"

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
  TYPE=1
elif [[ $OUTPUT_FILE == *"ncs.smp"* ]]; then
  TYPE=2
elif [[ $OUTPUT_FILE == *"NcsJVMLauncher"* ]]; then
  TYPE=3
else
  TYPE=4
fi


OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"



 
for (( i=$STARTI;i<=$DURATION;i++ ))
do
  SIGNALBACK_FILE="/tmp/signalback/nso_collect_start_signalback_$$_$i"
  # Wait for centralized controller signal
  if [ ! -z "$SIGNAL_FILE" ]; then
    log_verbose "Waiting for start signal..."
    #echo "Waiting for start signal..."

    while true; do
      if [ -f "$SIGNAL_FILE" ]; then
#        Data=$(cat $SIGNAL_FILE 2>/dev/null || echo 12345678999999  )
         Data=$(awk 'NR==1' $SIGNAL_FILE 2>/dev/null || echo 12345678999999)
        if  [[ $Data -eq $i ]]; then
              break
              log_verbose "Start signal received. Beginning data collection for PID $SCRIPT_NAME..."
        else
           sleep 0.1 
        fi
      else
         sleep 0.1
      fi
    done

  else 
      echo "SIGNAL_FILE Parameter not provided"
  fi

  #rm -f $SIGNALBACK_FILE
  # Tick!
  if  [[ $TYPE -eq 1 ]]; then
    PID=$(pgrep -f "./logs/ncs-python-vm -i $SCRIPT_NAME -s") #
  elif  [[ $TYPE -eq 2 ]]; then
    PID=$(pgrep -f "\.smp.*-ncs true") #./logs/ncs-python-vm -i 
  elif  [[ $TYPE -eq 3 ]]; then
    PID=$(pgrep -f "com.tailf.ncs.NcsJVMLauncher") #./logs/ncs-python-vm -i 
  else
    PID=$(pgrep -f "$SCRIPT_NAME") #./logs/ncs-python-vm -i 
  fi
  
  #echo $PID" "$SCRIPT_NAME" "$PYTHON_SWITCH" "$OUTPUT_FILE
  ALO_TOTAL=$(cat /proc/meminfo | grep 'Committed_AS' | awk -F' ' '{print $2}')
  Limit=$(cat /proc/meminfo | grep 'CommitLimit' | awk -F' ' '{print $2}')
  TIME=$(awk 'NR==2' $SIGNAL_FILE 2>/dev/null || echo 12345678999999)
  if [ ! -z "$PID" ]; then
    log_verbose "Monitoring PID: $PID"
    ALO_PID=$(pmap -d $PID | grep "writeable/private" | awk -F' ' '{print $4}' | egrep -o '[0-9.]+'  )
    PHY=$(cat /proc/$PID/status 2>/dev/null | grep VmRSS | awk -F' ' '{print $2}')
    #echo $ALO_PID

    if [ ! -z "$ALO_PID" ] && [ ! -z "$PHY" ]; then
      echo $TIME" "$PHY" "$ALO_PID" "$ALO_TOTAL" "$Limit $PID >> "$OUTPUT_FILE"
      if  [[ $TYPE -eq 2 ]]; then
          echo $TIME" "0" "0" "$ALO_TOTAL" "$Limit >> "$CACHE_FILE"
      fi
      log_verbose "$i second is collected to $OUTPUT_FILE"
    else
      #echo "empty 1"
      echo $TIME" "0" "0" "$ALO_TOTAL" "$Limit >> "$OUTPUT_FILE"
      log_verbose "$i second is collected to $OUTPUT_FILE"
    fi
  else
    #echo "empty 2"
    echo $TIME" "0" "0" "$ALO_TOTAL" "$Limit >> "$OUTPUT_FILE"
    log_verbose "$i second is collected to $OUTPUT_FILE"
  fi
  touch $SIGNALBACK_FILE

  ALO_PID=""
  PHY=""
  unset PID


 done

log_verbose "Collection for PID $PID done"
