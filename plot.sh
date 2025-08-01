#!/bin/bash


bash collect.sh ncs.smp $1 &
bash collect.sh NcsJVMLauncher $1 &
bash collect.sh python3 $1 &
wait
echo "Collection for for all process done"


bash graphs.sh ncs.smp
bash graphs.sh NcsJVMLauncher
bash graphs.sh python3

bash graphs_compare.sh


echo "Ploting graph for all process done"
