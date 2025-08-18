set terminal dumb enhanced ansi256
set xlabel "Iteration"
set ylabel "T\nh\nr\ne\na\nd\n\nI\nD\n" offset character 0,5 
unset key
set yrange [-1:9]
plot "schedule.dat" using 1:2
