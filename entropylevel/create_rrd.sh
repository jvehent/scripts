rrdtool create entropylvl.rrd --start 1257346000 --step 1 DS:entropylvl:GAUGE:5:0:4096 RRA:AVERAGE:0.9:1:604800 RRA:MIN:0.9:1:604800 RRA:MAX:0.9:1:604800
