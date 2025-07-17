set term png small size 800,600
set output "mem-graph.png"

set ylabel "RSS"
#set y2label "%MEM"
#set y2label "%Commited_AS"

set ytics nomirror 
#set y2tics nomirror in

set yrange [0:*]
#set y2range [0:*]


plot "data/mem.log" using 1 with lines axes x1y1 title "RSS" , \
     "data/mem.log" using 2 with lines axes x1y1 title "Allocated"
