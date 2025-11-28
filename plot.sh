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

# Find and collect for each process type
echo "Starting collection processes..."

NS=1000000000

mkdir -p data/python3
for (( i=0;i<=$DURATION;i++ ))
do
  START_TIME=$(date +%s%N)
  PYTHON_PIDS=$(pgrep -f "python.* .*startup\.py")
  JVM_PID=$(pgrep -f NcsJVMLauncher)
  NCS_PID=$(pgrep -f "\.smp.*-ncs true")

  # Collect ncs.smp or beam.smp NSO process
  if [ ! -z "$NCS_PID" ]; then
    #echo "Starting collection for ncs.smp PID $NCS_PID"
    COLLECT_PIDS=$(pgrep -f ".*collect.sh.* $NCS_PID")
    if [ -z "$COLLECT_PIDS" ]; then
      bash collect.sh $NCS_PID "data/ncs.smp/mem_ncs.smp.log" $DURATION $VERBOSE "$SIGNAL_FILE" &
    fi
  fi

  # Collect NcsJVMLauncher process
  if [ ! -z "$JVM_PID" ]; then
    #echo "Starting collection for NcsJVMLauncher PID $JVM_PID"
    COLLECT_PIDS=$(pgrep -f ".*collect.sh.* $JVM_PID")
    if [ -z "$COLLECT_PIDS" ]; then
      bash collect.sh $JVM_PID "data/NcsJVMLauncher/mem_NcsJVMLauncher.log" $DURATION $VERBOSE "$SIGNAL_FILE" &
    fi
  fi

  # Collect Python processes
  if [ ! -z "$PYTHON_PIDS" ]; then
    for pid in $PYTHON_PIDS; do
      COLLECT_PIDS=$(pgrep -f ".*collect.sh.* $pid")
      if [ -z "$COLLECT_PIDS" ]; then
        #echo "Not Found Collection Process for Python process PID $pid. Spwaning new Collection Process."
        PYTHON_SCRIPT=$(ps -p $pid -o command | tail -n 1 | awk -F' ' '{print $9}')
        SCRIPT_NAME=$(basename "$PYTHON_SCRIPT" .py 2>/dev/null || echo "python_$pid")
        if [ ! -z "$PYTHON_SCRIPT" ]; then
          #echo "Starting collection for Python process PID $pid: $SCRIPT_NAME"
          bash collect.sh $pid "data/python3/mem_$SCRIPT_NAME.log" $DURATION-$i $VERBOSE "$SIGNAL_FILE" &
        fi
      # else
      #   echo "Collection Process already running for Python process PID $pid"
      fi
    done
  # else
  #   echo "No Python processes found to collect. for second $i"
  fi
 

  
  END_TIME=$(date +%s%N)
  ELAPSED=$(($END_TIME - $START_TIME))
  SLEEP_TIME=$(($NS - $ELAPSED))
  if (( SLEEP_TIME > 0 )); then
    SLEEP_SECONDS=$(awk "BEGIN {printf \"%.9f\", $SLEEP_TIME/$NS}")
    #echo $SLEEP_SECONDS
    sleep $SLEEP_SECONDS
  fi

  # Signal all processes to start collecting
  touch "$SIGNAL_FILE"
  wait
  echo -ne "Data Collection - $i second out of $DURATION second"\\r

  # Clean up signal file
  rm -f "$SIGNAL_FILE"
  pkill -f collect.sh
#  # Give a moment for all processes to register
#  sleep 1
done

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