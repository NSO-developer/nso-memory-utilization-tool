if (GPVAL_VERSION >= 5.0) set for [i=1:8] linetype i dashtype i
if (GPVAL_VERSION < 5.0) set termoption dashed

if (!exists("verbose")) verbose = 0

if (verbose == 1) {
    print "Statistical Data for Commited_AS"
    stats 'data/mem.log' using 4
} else {
    stats 'data/mem.log' using 4 nooutput
}
print "Recommended CommitLimit: ",STATS_max
print "Please add some buffer range based on the Recommended CommitLimit"

if (verbose == 1) {
    print "Statistical Data for RSS"
    stats 'data/mem.log' using 2
} else {
    stats 'data/mem.log' using 2 nooutput
}

if (verbose == 1) {
    print "Statistical Data for Allocated"
    stats 'data/mem.log' using 3
} else {
    stats 'data/mem.log' using 3 nooutput
}



set term png small size 800,600
set output "mem-graph.png"

set ylabel "MEM(kb)"
set xlabel "Time"

set ytics nomirror 
#set y2tics nomirror in

set yrange [0:*]
#set y2range [0:*]

set xdata time
set timefmt '%H:%M:%S'
set format x '%H:%M:%S'
#set xrange ['00:00':'24:00']


show style line

#set y2label "%MEM"
#set y2label "%Commited_AS"



plot "data/mem.log" using 1:5 with lines axes x1y1 lc 'red' lw 2 title "CommitLimit", \
     "data/mem.log" using 1:4 with lines axes x1y1 title "Commited_AS", \
     "data/mem.log" using 1:2 with lines axes x1y1 title "RSS" , \
     "data/mem.log" using 1:3 with lines axes x1y1 title "Allocated"
