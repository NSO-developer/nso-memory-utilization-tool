#!/bin/bash

NS=1000000000

PID=$1
OUTPUT_FILE=$2
DURATION=$3
VERBOSE=${4:-0}
SIGNAL_FILE=$5
PARENT_PID=$PPID

if [ -z "$PID" ] || [ -z "$OUTPUT_FILE" ] || [ -z "$DURATION" ]; then
  echo "Usage: $0 <pid> <output_file> <duration> [verbose_flag] [signal_file]"
  exit 1
fi

log_verbose() {
  if [ $VERBOSE -eq 1 ]; then
    echo "$1"
  fi
}

check_parent() {
  if ! kill -0 $PARENT_PID 2>/dev/null; then
    log_verbose "Parent process $PARENT_PID has died. Terminating collection for PID $PID."
    exit 0
  fi
}

OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"


# Wait for all collection processes to be ready before starting
if [ ! -z "$SIGNAL_FILE" ]; then
  log_verbose "Waiting for start signal..."

  while [ ! -f "$SIGNAL_FILE" ]; do
    sleep 0.1
  done

  log_verbose "Start signal received. Beginning data collection for PID $PID..."
fi

for (( i=0;i<=$DURATION;i++ ))
do
  START_TIME=$(date +%s%N)

  check_parent

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

  END_TIME=$(date +%s%N)
  ELAPSED=$(($END_TIME - $START_TIME))
  SLEEP_TIME=$(($NS - $ELAPSED))

  if (( SLEEP_TIME > 0 )); then
    SLEEP_SECONDS=$(awk "BEGIN {printf \"%.9f\", $SLEEP_TIME/$NS}")
    sleep $SLEEP_SECONDS
  fi
done

echo "Collection for PID $PID done"
