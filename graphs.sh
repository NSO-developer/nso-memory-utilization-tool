#!/bin/bash

VERBOSE=${2:-0}




PY_CHECK=0

case "$1" in
     "python3") 
        PY_CHECK=1
        ;;

     "python") 
        PY_CHECK=1
        ;;
     *)
        PY_CHECK=0
        ;;
    esac

rm -rf graphs/$1
rm -f *.png
mkdir graphs/$1



for filename in data/$1/*.log; do
  if [ $PY_CHECK -eq 1 ]; then
     name=$(echo $filename | awk -F'_' '{print $2}'| awk -F'.' '{print $1}')
  else
    name=$1
  fi
  name=$(echo $name)
  rm -f data/mem.log
  if [ ! -z "${name}" ]; then
    echo "generated graph for pid "$name
    ln -s $PWD/data/$1/mem_$name.log $PWD/data/mem.log
    if [ $PY_CHECK -eq 1 ]; then
       gnuplot -e "verbose=$VERBOSE" show_mem_2.plt
    else
       gnuplot -e "verbose=$VERBOSE" show_mem.plt
    fi

    cp mem-graph.png graphs/$1/mem_$name.png
  fi
done


if [ $PY_CHECK -eq 1 ]; then
  name="total"
  echo "generated graph for total "$name
  rm -f data/mem.log
  ln -s $PWD/data/$1/mem_$name.log $PWD/data/mem.log
  gnuplot -e "verbose=$VERBOSE" show_mem.plt
  cp mem-graph.png graphs/$1/mem_$name.png
fi

rm -f graphs/mem_.png
rm -f graphs/mem_--multiprocessing-fork.png
