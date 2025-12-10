#!/bin/bash

VERBOSE=0
DURATION=""

create_combined_python_log() {
  echo "Creating combined Python total log..."

  if ! ls data/python3/mem_*.log >/dev/null 2>&1; then
    echo "No Python process logs found to combine"
    return
  fi

  num_files=$(find data/python3 -name "mem_*.log" ! -name "mem_total.log" | wc -l)

  find data/python3 -name "mem_*.log" ! -name "mem_total.log" -exec cat {} \; | awk -v num_files="$num_files" '
  {
    timestamp = $1
    rss = $2
    alloc = $3
    system_total = $4
    limit = $5

    totals[timestamp,"rss"] += rss
    totals[timestamp,"alloc"] += alloc
    totals[timestamp,"system"] = system_total
    totals[timestamp,"limit"] = limit

    count[timestamp]++

    if (!(timestamp in seen)) {
      timestamps[++ts_count] = timestamp
      seen[timestamp] = 1
    }
  }
  END {
    for (i = 1; i <= ts_count; i++) {
      ts = timestamps[i]
      if (count[ts] == num_files) {
        print ts, totals[ts,"rss"], totals[ts,"alloc"], totals[ts,"system"], totals[ts,"limit"]
      }
    }
  }
  ' | sort > data/python3/mem_total.log

  echo "Combined Python total log created"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    *)
      DURATION="$1"
      shift
      ;;
  esac
done

if [ -z "$DURATION" ]; then
  echo "Usage: $0 [--verbose|-v] <duration>"
  echo "  duration: Collection duration in seconds"
  echo "  --verbose: Enable verbose logging"
  exit 1
fi

# Clean up old data
rm -rf data/ncs.smp data/NcsJVMLauncher data/python3

echo "====================================== Collection for for all process ====================================================="

# Create a signal file to coordinate process startup
SIGNAL_FILE="/tmp/nso_collect_start_signal_$$"
rm -f "$SIGNAL_FILE"

rm -rf /tmp/signalback
mkdir "/tmp/signalback"

# Find and collect for each process type
echo "Starting collection processes..."

NS=1000000000
counter=0

CACHE_FILE="/tmp/cache.log"
touch $CACHE_FILE

mkdir -p data/python3
for (( i=0;i<=$DURATION;i++ ))
do
  START_TIME=$(date +%s%N)
  PYTHON_PIDS=$(pgrep -f "python.* .*startup\.py")
  JVM_PID=$(pgrep -f com.tailf.ncs.NcsJVMLauncher)
  NCS_PID=$(pgrep -f "\.smp.*-ncs true")

  # Collect ncs.smp or beam.smp NSO process
  if [ ! -z "$NCS_PID" ]; then
    COLLECT_PIDS=$(pgrep -f '.*collect.sh.*ncs.smp')
    if [ -z "$COLLECT_PIDS" ]; then
      echo "New ncs.smp process PID $NCS_PID: ncs.smp. Start Collection"
      counter=$((counter+1))
      bash collect.sh ncs.smp "data/ncs.smp/mem_ncs.smp.log" $DURATION $VERBOSE "$SIGNAL_FILE" $i &
    fi
  fi

  # Collect NcsJVMLauncher process
  if [ ! -z "$JVM_PID" ]; then
    COLLECT_PIDS=$(pgrep -f ".*collect.sh.*NcsJVMLauncher")
    if [ -z "$COLLECT_PIDS" ]; then
      echo "New JVM process PID $JVM_PID: NcsJVMLauncher. Start Collection"
      counter=$((counter+1))
      bash collect.sh NcsJVMLauncher "data/NcsJVMLauncher/mem_NcsJVMLauncher.log" $DURATION $VERBOSE "$SIGNAL_FILE" $i &
    fi
  fi

  # Collect Python processes
  if [ ! -z "$PYTHON_PIDS" ]; then
    for pid in $PYTHON_PIDS; do
      PYTHON_SCRIPT=$(ps -p $pid -o command | tail -n 1 | awk -F' ' '{print $9}')
      SCRIPT_NAME=$(basename "$PYTHON_SCRIPT" .py 2>/dev/null || echo "python_$pid")
      COLLECT_PIDS=$(pgrep -f ".*collect.sh.* $SCRIPT_NAME")
      if [ -z "$COLLECT_PIDS" ]; then
        if [ ! -z "$PYTHON_SCRIPT" ]; then
          echo "New Python process PID $pid: $SCRIPT_NAME. Start Collection"
          cp $CACHE_FILE "data/python3/mem_$SCRIPT_NAME.log"
          counter=$((counter+1))
          bash collect.sh "$SCRIPT_NAME" "data/python3/mem_$SCRIPT_NAME.log" $DURATION $VERBOSE "$SIGNAL_FILE" $i &
        fi
      fi
    done
  fi
 

  
  sleep 0.1
  # Signal all processes to start collecting
  TIME=$(date +%T)
  echo $i > $SIGNAL_FILE
  echo $TIME >> $SIGNAL_FILE

  while [[ $(ps -aux | grep "collect.sh" | wc -l) -gt $(($(ls "/tmp/signalback/" | grep "nso_collect_start_signalback_.*_$i" | wc -l)+1)) ]]; do
      sleep 0.1
    done

  # Clean up signal file
  rm -f $SIGNAL_FILE
  rm -rf /tmp/signalback/*
  

  END_TIME=$(date +%s%N)
  ELAPSED=$(($END_TIME - $START_TIME))
  SLEEP_TIME=$(($NS - $ELAPSED))
  if (( SLEEP_TIME > 0 )); then
    SLEEP_SECONDS=$(awk "BEGIN {printf \"%.9f\", $SLEEP_TIME/$NS}")
    #echo $SLEEP_SECONDS
    sleep $SLEEP_SECONDS
  fi

  echo -ne "Data Collection - $i second out of $DURATION second"\\r

done


wait


pkill -f collect.sh
rm -rf /tmp/signalback
rm $CACHE_FILE
echo ""
echo "Data Collection - OK!"

sleep 2


if [ ! -z "$PYTHON_PIDS" ]; then
  create_combined_python_log
fi

echo "===================================== Collection for for all process done  ================================================="


echo "====================================== Ploting graph to all process ========================================================"
echo "====================================== Ploting graph for ncs.smp process ========================================================"
bash graphs.sh ncs.smp $VERBOSE
echo -e "===================================== Ploting graph for ncs.smp process done  =================================================\n"
echo "====================================== Ploting graph for NcsJVMLauncher process ========================================================"
bash graphs.sh NcsJVMLauncher $VERBOSE
echo "===================================== Ploting graph for NcsJVMLauncher process done  =================================================\n"
echo "====================================== Ploting graph for python3 processes ========================================================\n"
if [ -d "data/python3" ]; then
  echo "Plotting combined graph for python3 processes"
  bash graphs.sh python3 $VERBOSE
else
  echo "No python3 data directory found"
fi
echo "===================================== Ploting graph for python3 processes done  =================================================\n"
echo "====================================== Ploting graph to compare between process ========================================================"
bash graphs_compare.sh $VERBOSE
echo -e "====================================== Ploting graph to compare between process done ========================================================\n"
echo "===================================== Ploting graph to all process done  ================================================="
