if (GPVAL_VERSION >= 5.0) set for [i=1:8] linetype i dashtype i
if (GPVAL_VERSION < 5.0) set termoption dashed

set term png small size 800,600
set output "graphs/compare/mem-graph-compare-allocate.png"

set ylabel "MEM(kb)"
set xlabel "Time"

#set y2label "%MEM"
#set y2label "%Commited_AS"

set ytics nomirror 
#set y2tics nomirror in

set yrange [0:*]
#set y2range [0:*]

set xdata time
set timefmt '%H:%M:%S'
set format x '%H:%M:%S'
#set xrange ['00:00':'24:00']


show style line



plot "data/mem_total.log" using 1:5 with lines axes x1y1 lc 'red' lw 2 title "CommitLimit", \
     "data/mem_total.log" using 1:4 with lines axes x1y1 title "Commited_AS", \
     "data/mem_ncs.smp.log" using 1:3 with lines axes x1y1 title "ncs.smp", \
     "data/mem_total.log" using 1:3 with lines axes x1y1 title "PythonVM(Total)", \
     "data/mem_NcsJVMLauncher.log" using 1:3 with lines axes x1y1 title "JavaVM"
