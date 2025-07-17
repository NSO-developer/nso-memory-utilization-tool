#!/bin/bash




PID=$(pgrep -f $1)
echo "Monitoring PID: "$PID

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



if [ $PY_CHECK -eq 0 ]; then
  PID=$(echo $PID  | awk -F' ' '{print $1}')
fi


for pid in $PID ; do
  if [ $PY_CHECK -eq 1 ]; then
    name=$(ps -p $pid -o command | awk -F' ' '{print $9}')
  else
    name=$1
  fi
  name=$(echo $name)
  echo "generated graph for pid "$name
  rm data/mem.log
  ln -s $PWD/data/mem_$name.log $PWD/data/mem.log

  if [ $PY_CHECK -eq 1 ]; then
     gnuplot show_mem_2.plt
  else
     gnuplot show_mem.plt
  fi
  cp mem-graph.png graphs/$1/mem_$name.png
done


if [ $PY_CHECK -eq 1 ]; then
  name="total"
  echo "generated graph for total "$name
  rm data/mem.log
  ln -s $PWD/data/mem_$name.log $PWD/data/mem.log
  gnuplot show_mem.plt
  cp mem-graph.png graphs/$1/mem_$name.png
fi

rm -f graphs/mem_.png
rm -f graphs/mem_--multiprocessing-fork.png
