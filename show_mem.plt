if (GPVAL_VERSION >= 5.0) set for [i=1:8] linetype i dashtype i
if (GPVAL_VERSION < 5.0) set termoption dashed

set term png small size 800,600
set output "mem-graph.png"

set ylabel "RSS"
#set y2label "%MEM"
#set y2label "%Commited_AS"

set ytics nomirror 
#set y2tics nomirror in

set yrange [0:*]
#set y2range [0:*]

show style line


plot "data/mem.log" using 4 axes x1y1 lt 2 lc 'red' title "CommitLimit", \
     "data/mem.log" using 3 with lines axes x1y1 title "Commited_AS", \
     "data/mem.log" using 1 with lines axes x1y1 title "RSS" , \
     "data/mem.log" using 2 with lines axes x1y1 title "Allocated"
