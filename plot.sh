#!/bin/bash

VERBOSE=0
DURATION=""

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

echo "====================================== Collection for for all process ====================================================="
bash collect.sh ncs.smp $DURATION $VERBOSE &
bash collect.sh NcsJVMLauncher $DURATION $VERBOSE &
bash collect.sh python3 $DURATION $VERBOSE &
wait
echo -e "===================================== Collection for for all process done  =================================================\n\n"


echo "====================================== Ploting graph to all process ========================================================"
echo "====================================== Ploting graph for ncs.smp process ========================================================"
bash graphs.sh ncs.smp $VERBOSE
echo -e "===================================== Ploting graph for ncs.smp process done  =================================================\n"
echo "====================================== Ploting graph for NcsJVMLauncher process ========================================================"
bash graphs.sh NcsJVMLauncher $VERBOSE
echo -e "===================================== Ploting graph for NcsJVMLauncher process done  =================================================\n"
echo "====================================== Ploting graph for python3 process ========================================================"
bash graphs.sh python3 $VERBOSE
echo -e "===================================== Ploting graph for python3 process done  =================================================\n"
echo "====================================== Ploting graph to compare between process ========================================================"
bash graphs_compare.sh $VERBOSE
echo -e "====================================== Ploting graph to compare between process done ========================================================\n"
echo "===================================== Ploting graph to all process done  ================================================="
