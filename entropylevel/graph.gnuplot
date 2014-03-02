set title "Entropy level on zerhuel.linuxwal.info"
set xlabel "time"
set ylabel "bits"
set yrange [0:4200]

set terminal png
set output "/data/www/pki/entropy_level.png"

set xdata time
set timefmt "%s"
set format x "%d/%m/%y:%Hh%M"
set xtics nomirror rotate
# offset 0,-7
set datafile separator ":"
plot '/data/julien/code/scripts/entropylevel/entlvl.log' using 1:2 with dots
#plot ["1257410960":"1257413400"] 'entlvl.log' using 1:2 with linespoints
