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

# Collect ncs.smp or beam.smp NSO process
NCS_PID=$(pgrep -f "\.smp.*-ncs true")
if [ ! -z "$NCS_PID" ]; then
  echo "Starting collection for ncs.smp PID $NCS_PID"
  bash collect.sh $NCS_PID "data/ncs.smp/mem_ncs.smp.log" $DURATION $VERBOSE "$SIGNAL_FILE" &
fi

# Collect NcsJVMLauncher process
JVM_PID=$(pgrep -f NcsJVMLauncher)
if [ ! -z "$JVM_PID" ]; then
  echo "Starting collection for NcsJVMLauncher PID $JVM_PID"
  bash collect.sh $JVM_PID "data/NcsJVMLauncher/mem_NcsJVMLauncher.log" $DURATION $VERBOSE "$SIGNAL_FILE" &
fi

# Collect Python processes
PYTHON_PIDS=$(pgrep -f "python.* .*startup\.py")
if [ ! -z "$PYTHON_PIDS" ]; then
  mkdir -p data/python3
  for pid in $PYTHON_PIDS; do
    PYTHON_SCRIPT=$(ps -p $pid -o command | tail -n 1 | awk -F' ' '{print $9}')
    SCRIPT_NAME=$(basename "$PYTHON_SCRIPT" .py 2>/dev/null || echo "python_$pid")
    if [ ! -z "$PYTHON_SCRIPT" ]; then
      echo "Starting collection for Python process PID $pid: $SCRIPT_NAME"
      bash collect.sh $pid "data/python3/mem_$SCRIPT_NAME.log" $DURATION $VERBOSE "$SIGNAL_FILE" &
    fi
  done
else
  echo "No Python processes found to collect"
fi

# Give a moment for all processes to register
sleep 1

# Signal all processes to start collecting
echo "All collection processes started. Signaling to begin data collection..."
touch "$SIGNAL_FILE"

wait

# Clean up signal file
rm -f "$SIGNAL_FILE"

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
