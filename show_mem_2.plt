set term png small size 800,600
set output "mem-graph.png"

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


plot "data/mem.log" using 1:2 with lines axes x1y1 title "RSS" , \
     "data/mem.log" using 1:3 with lines axes x1y1 title "Allocated"
