#!/bin/bash

echo "====================================== Collection for for all process ====================================================="
bash collect.sh ncs.smp $1 &
bash collect.sh NcsJVMLauncher $1 &
bash collect.sh python3 $1 &
wait
echo -e "===================================== Collection for for all process done  =================================================\n\n"


echo "====================================== Ploting graph to all process ========================================================"
echo "====================================== Ploting graph for ncs.smp process ========================================================"
bash graphs.sh ncs.smp
echo -e "===================================== Ploting graph for ncs.smp process done  =================================================\n"
echo "====================================== Ploting graph for NcsJVMLauncher process ========================================================"
bash graphs.sh NcsJVMLauncher
echo -e "===================================== Ploting graph for NcsJVMLauncher process done  =================================================\n"
echo "====================================== Ploting graph for python3 process ========================================================"
bash graphs.sh python3
echo -e "===================================== Ploting graph for python3 process done  =================================================\n"
echo "====================================== Ploting graph to compare between process ========================================================"
bash graphs_compare.sh
echo -e "====================================== Ploting graph to compare between process done ========================================================\n"
echo "===================================== Ploting graph to all process done  ================================================="
