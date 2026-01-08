#!/bin/bash

NS=1000000000


# SCRIPT_NAME=$1
# PID=$(pgrep -f "$SCRIPT_NAME")
# OUTPUT_FILE=$2
DURATION=$1
VERBOSE=${2:-0}
SIGNAL_FILE=$3
STARTI=$4
CACHE_FILE="/tmp/cache.log"

ALLOC_LIMIT_PERCENT=90
RSS_LIMIT_PERCENT=90

if  [ -z "$DURATION" ]; then
  echo "Usage: $0 <duration> [verbose_flag] [signal_file]"
  exit 1
fi

log_verbose() {
  timestamp=$(date)
  if [ $VERBOSE -eq 1 ]; then
    echo $timestamp" [VERBOSE] "$1
  fi
}

log_error () {
    timestamp=$(date)
    echo $timestamp" [ERR] "$1 
}

log_monitor () {
    timestamp=$(date)
    echo $timestamp" [MONITOR] "$1 
}


log_monitor_verbose () {
    timestamp=$(date)
      if [ $VERBOSE -eq 1 ]; then
    echo $timestamp" [MONITOR VERBOSE] "$1 
  fi
}
# if [[ $OUTPUT_FILE == *"python3"* ]]; then
#   TYPE=1
# elif [[ $OUTPUT_FILE == *"ncs.smp"* ]]; then
#   TYPE=2
# elif [[ $OUTPUT_FILE == *"NcsJVMLauncher"* ]]; then
#   TYPE=3
# else
#   TYPE=4
# fi


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

  # Collection
  # General System Status
  # Allocated
  ALO_TOTAL=$(cat /proc/meminfo | grep 'Committed_AS' | awk -F' ' '{print $2}')
  Limit=$(cat /proc/meminfo | grep 'CommitLimit' | awk -F' ' '{print $2}')
  # Physical
  MemFree=$(cat /proc/meminfo | grep 'MemFree' | awk -F' ' '{print $2}')
  MemTotal=$(cat /proc/meminfo | grep 'MemTotal' | awk -F' ' '{print $2}')
  MemUsed=$(($MemTotal-$MemFree))
  #TIME=$(awk 'NR==2' $SIGNAL_FILE 2>/dev/null || echo 12345678999999)
    
    # Monitor
    # Committed_AS vs CommitLimit
    # MemFree vs MemTotal
    ALO_LIMIT=$(( $Limit*$ALLOC_LIMIT_PERCENT/100 ))
    RSS_LIMIT=$(( $MemTotal*$RSS_LIMIT_PERCENT/100 ))

    if [ $ALO_TOTAL -lt $ALO_LIMIT ]; then
        log_monitor_verbose "[INFO] Committed_AS $ALO_TOTAL KB/$ALO_LIMIT KB is within $ALLOC_LIMIT_PERCENT% of CommitLimit"
      else
        log_monitor "[WARNING] Committed_AS $ALO_TOTAL KB/$ALO_LIMIT KB exceeded $ALLOC_LIMIT_PERCENT% of CommitLimit"
    fi

    if [ $MemUsed -lt $RSS_LIMIT ]; then
        log_monitor_verbose "[INFO] Physical Memory Usage $MemUsed KB/$RSS_LIMIT KB is within $RSS_LIMIT_PERCENT% of MemTotal"
      else
        log_monitor "[WARNING] Physical Memory Usage $MemUsed KB/$RSS_LIMIT KB exceeded $RSS_LIMIT_PERCENT% of MemTotal"
    fi

  # fi
  touch $SIGNALBACK_FILE

  # Allocated
  ALO_TOTAL=""
  Limit=""
  # Physical
  MemFree=$(cat /proc/meminfo | grep 'MemFree' | awk -F' ' '{print $2}')
  MemTotal=$(cat /proc/meminfo | grep 'MemTotal' | awk -F' ' '{print $2}')
  MemUsed=$(($MemTotal-$MemFree))

 done
