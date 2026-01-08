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

log_error () {
    timestamp=$(date)
    echo $timestamp" [ERR] "$1 
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

MemTotal=$(cat /proc/meminfo | grep 'MemTotal' | awk -F' ' '{print $2}') 

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
      log_error "SIGNAL_FILE Parameter not provided"
  fi

  #rm -f $SIGNALBACK_FILE
  # Tick!
  if  [[ $TYPE -eq 1 ]]; then
    PID=$(pgrep -f "./logs/ncs-python-vm -i $SCRIPT_NAME -s") #
    #possible multiprocessing mode
    SUBPIDS=$(ps --forest -o pid -g $PID | sed 1,2d)
    #echo "Subprocess PID detected: "$SUBPIDS for $PID
  elif  [[ $TYPE -eq 2 ]]; then
    PID=$(pgrep -f "\.smp.*-ncs true") #./logs/ncs-python-vm -i 
    SUBPIDS=""
  elif  [[ $TYPE -eq 3 ]]; then
    PID=$(pgrep -f "com.tailf.ncs.NcsJVMLauncher") #./logs/ncs-python-vm -i 
    SUBPIDS=""
  else
    PID=$(pgrep -f "$SCRIPT_NAME") #./logs/ncs-python-vm -i 
    SUBPIDS=""
  fi
  
  #echo $PID" "$SCRIPT_NAME" "$PYTHON_SWITCH" "$OUTPUT_FILE
  # Collection
  # General System Status
  # Allocated
  ALO_TOTAL=$(cat /proc/meminfo | grep 'Committed_AS' | awk -F' ' '{print $2}')
  Limit=$(cat /proc/meminfo | grep 'CommitLimit' | awk -F' ' '{print $2}')
  # Physical
  MemFree=$(cat /proc/meminfo | grep 'MemFree' | awk -F' ' '{print $2}')
  MemTotal=$(cat /proc/meminfo | grep 'MemTotal' | awk -F' ' '{print $2}')
  MemUsed=$(($MemTotal-$MemFree))

  # Per Process
  if [ ! -z "$PID" ]; then
    log_verbose "Monitoring PID: $PID"
    ALO_PID=$(pmap -d $PID | grep "writeable/private" | awk -F' ' '{print $4}' | egrep -o '[0-9.]+'  )
    PHY=$(cat /proc/$PID/status 2>/dev/null | grep VmRSS | awk -F' ' '{print $2}')
    if [ ! -z "$SUBPIDS" ]; then
       for SUBPID in $SUBPIDS; do
          log_verbose "Subprocess PID detected: $PID"
          #echo "Subprocess PID detected: $PID. Current ALO_PID $ALO_PID Before Addition" 
          ALO_SUBPID=$(pmap -d $SUBPID | grep "writeable/private" | awk -F' ' '{print $4}' | egrep -o '[0-9.]+'  )
          PHY_SUBPID=$(cat /proc/$SUBPID/status 2>/dev/null | grep VmRSS | awk -F' ' '{print $2}')
          ALO_PID=$(($ALO_PID+$ALO_SUBPID))
          #echo "Subprocess PID detected: $PID. Current ALO_PID $ALO_PID After Addition"
          PHY=$(($PHY+$PHY_SUBPID))
       done
    fi
    TIME=$(awk 'NR==2' $SIGNAL_FILE 2>/dev/null || echo 12345678999999)
    
    # Monitor
    # Committed_AS vs CommitLimit
    # MemFree vs MemTotal

    #echo $ALO_PID

    if [ ! -z "$ALO_PID" ] && [ ! -z "$PHY" ]; then
      echo $TIME" "$PHY" "$ALO_PID" "$ALO_TOTAL" "$Limit" "$MemUsed" "$MemTotal $PID >> "$OUTPUT_FILE"
      if  [[ $TYPE -eq 2 ]]; then
          echo $TIME" "0" "0" "$ALO_TOTAL" "$Limit" "$MemUsed" "$MemTotal >> "$CACHE_FILE"
      fi
      log_verbose "$i second is collected to $OUTPUT_FILE"
    else
      #echo "empty 1"
      echo $TIME" "0" "0" "$ALO_TOTAL" "$Limit" "$MemUsed" "$MemTotal >> "$OUTPUT_FILE"
      log_verbose "$i second is collected to $OUTPUT_FILE"
    fi
  else
    #echo "empty 2"
    echo $TIME" "0" "0" "$ALO_TOTAL" "$Limit" "$MemUsed" "$MemTotal >> "$OUTPUT_FILE"
    log_verbose "$i second is collected to $OUTPUT_FILE"
  fi
  touch $SIGNALBACK_FILE

  ALO_PID=""
  PHY=""
  BACKUP_PID=$PID
  BACKUP_SUBPIDS=$SUBPIDS
  unset PID
  unset SUBPIDS
 done

log_verbose "Collection for PID $BACKUP_PID done"
if [ ! -z "$BACKUP_SUBPIDS" ]; then
    sleep 1
    echo -e "\n\nRECOMMENDATION: Python package - PID "$BACKUP_PID":"$SCRIPT_NAME" has multipocess callpoint-model enabled. Recommend to change to threading mode for better memory utilization."
    ps --forest -o pid,cmd -g $BACKUP_PID
    echo -e ""
fi
