if (GPVAL_VERSION >= 5.0) set for [i=1:8] linetype i dashtype i
if (GPVAL_VERSION < 5.0) set termoption dashed

if (!exists("verbose")) verbose = 0

if (verbose == 1) {
    print "Statistical Data for Memory Allocation on JavaVM "
    stats 'data/NcsJVMLauncher/mem_NcsJVMLauncher.log' using 3
} else {
    stats 'data/NcsJVMLauncher/mem_NcsJVMLauncher.log' using 3 nooutput
}

if (verbose == 1) {
    print "Statistical Data for Memory Allocation on PythonVM(Total)"
    stats 'data/python3/mem_total.log' using 3
} else {
    stats 'data/python3/mem_total.log' using 3 nooutput
}

if (verbose == 1) {
    print "Statistical Data for Memory Allocation on ncs.smp"
    stats 'data/ncs.smp/mem_ncs.smp.log' using 3
} else {
    stats 'data/ncs.smp/mem_ncs.smp.log' using 3 nooutput
}

if (verbose == 1) {
    print "Statistical Data for Commited_AS"
    stats 'data/python3/mem_total.log' using 4
} else {
    stats 'data/python3/mem_total.log' using 4 nooutput
}
print "RECOMMENDATION: Recommended CommitLimit: ",STATS_max
print "RECOMMENDATION: Please add some buffer range based on the Recommended CommitLimit"

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

plot "data/ncs.smp/mem_ncs.smp.log" using 1:5 with lines axes x1y1 lc 'red' lw 2 title "CommitLimit", \
     "data/ncs.smp/mem_ncs.smp.log" using 1:4 with lines axes x1y1 title "Commited_AS", \
     "data/ncs.smp/mem_ncs.smp.log" using 1:3 with lines axes x1y1 title "ncs.smp", \
     "data/python3/mem_total.log" using 1:3 with lines axes x1y1 title "PythonVM(Total)", \
     "data/NcsJVMLauncher/mem_NcsJVMLauncher.log" using 1:3 with lines axes x1y1 title "JavaVM"
