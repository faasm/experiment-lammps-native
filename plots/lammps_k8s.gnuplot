#!/usr/bin/gnuplot
set terminal postscript color eps enhanced font 22
set output 'lammps_k8s.eps'
set datafile separator " "
set multiplot layout 2,1
set xlabel "Number of MPI Processes"
set xrange [1:16]


# Elapsed time plot
set title "{/Bold Elapsed Time}"
set ylabel "Time Elapsed [s]"
#set yrange [5:15]
cols = int(system('head -1 ../results/lammps_native_k8s.log | wc -w'))
plot '../results/lammps_native_k8s.log' \
       using 1:int(cols - 1) w lp pt 7 title 'Vanilla @ k8s' ,\
    '' using 1:int(cols - 1):cols w yerrorbars notitle

# Speedup
set title "{/Bold Speedup}"
#set yrange [1:10]
ref = int(system("head -1 ../results/lammps_native_k8s.log | rev | cut -d' ' -f2 | rev"))
plot '../results/lammps_native_k8s.log' \
        using 1:(ref/$5) w lp pt 7 title 'Vanilla @ k8s', \
    '' using 1:1 w lp lt 2 notitle
    

!epstopdf 'lammps_k8s.eps'
!rm 'lammps_k8s.eps'
