#!/bin/bash


rm -rf graphs/compare
mkdir graphs/compare


gnuplot compare_mem_alloc.plt
gnuplot compare_mem_rss.plt

