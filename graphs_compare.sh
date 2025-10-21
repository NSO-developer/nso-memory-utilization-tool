#!/bin/bash

VERBOSE=${1:-0}

echo "====================================== Plotting graph to compare between process ========================================================"

rm -rf graphs/compare
mkdir graphs/compare


gnuplot -e "verbose=$VERBOSE" compare_mem_alloc.plt
gnuplot -e "verbose=$VERBOSE" compare_mem_rss.plt

echo "====================================== Plotting graph to compare between process done ========================================================"
