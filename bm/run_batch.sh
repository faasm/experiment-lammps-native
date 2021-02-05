#!/bin/bash

set -e

NUM_PROCS=(1 2 4 8 16 32)
NUM_RUNS=4
OUT_FILE=lammps_native_k8s.log
rm -f ${OUT_FILE}

for np in ${NUM_PROCS[@]}; do
    echo "Running benchmark with $np processes."
    declare -a result_arr=()
    for ((run=1; run<=$NUM_RUNS; run++)); do
        echo " - Run # $run/${NUM_RUNS}"
        result_arr+=( $(MPI_NP=$np /code/experiment-lammps-native/k8s/run_single.sh) )
    done

    # Compute average and stdev
    avg=$(echo ${result_arr[@]} | \
        awk '{sum = 0; for (i = 1; i <= NF; i++) sum += $i; sum /= NF; print sum}')
    # Note: we use the uncorrected sample standard deviation. If we want to
    # use the unbiased estimator we need to divide by N - 1
    stdev=$(echo ${result_arr[@]} | \
        awk '{sum = 0; sum2=0; \
            for (i = 1; i <= NF; i++) \
                { sum += $i; sum2 += $i * $i; } \
            sum /= NF; sum2 /= NF; \
            print sqrt(sum2 - sum * sum)}')

    # Print results
    echo "${np} ${result_arr[@]} ${avg} ${stdev}" >> ${OUT_FILE}
done

