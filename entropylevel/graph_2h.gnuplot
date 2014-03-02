set title "Entropy level on zerhuel.linuxwal.info"
set xlabel "time"
set ylabel "bits"
set yrange [0:4200]

set terminal png
set output "/data/www/pki/entropy_level_2h.png"

set xdata time
set timefmt "%s"
set format x "%d/%m/%y:%Hh%M"
set xtics nomirror rotate
# offset 0,-7
set datafile separator ":"
plot 'ent_2h_20091207.txt' using 1:2 with lines
#plot ["1257410960":"1257413400"] 'entlvl.log' using 1:2 with linespoints
