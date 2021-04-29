: '
bash grid-search-2d.sh <inputimg> <brainmask> <lesionmask> <measureimg> <outdir>
'
scriptdir=$(dirname $0)

inputimg=$1
brainmask=$2
lesionmask=$3
measureimg=$4
# Output directory of model projections.
# Also used to save params.txt files for use in each process
outdir=$5

# Number of CPU processes to use. Will create an additional process if 
# necessary for processing remaining data
nprocs=$(($(nproc)/2))
#nprocs=2

# 2D grid search space

# Min and max tumor infiltration x and resolution
# x=1-y, y element [0,1]; 0=largest brain coverage
minif=0.01
maxif=0.9
resif=4

# Min and max displacement magnitude and resolution
mindisp=-5
maxdisp=5
resdisp=4

numsims=$(($resdisp * $resif))

if [[ $nprocs -gt $numsims ]]; then
    echo "The number of configurations to search is smaller than the number of processes specified. Setting numbers of processes to use as the number of configurations"
    nprocs=$numsims
fi

echo "Number of model projections to search:" $numsims

createparamsfile(){
    # Create <procs> number of parameter configuration files for independent runs
    disps2=$1
    ifs=$2
    IFS="=" # Internal Field Separator, used for word splitting
    while read -r k v; do
        if [[ $k = "displacement" ]]; then
            echo ${k}=$disps2
        elif [[ $k = "intensity_decay_fraction" ]]; then
            echo ${k}=$ifs
        else
            echo ${k}=${v}
        fi
    done <<< 'displacement=
gaussian_range_one_sided=5
intensity_decay_fraction=
num_vecs=32
angle_thr=7
spline_order=1
smoothing_std=4
perlin_noise_res=0.03
perlin_noise_abs_max=0'
}

linspacefromto_old(){
    from=$1
    to=$2
    num=$3
    for ((i=0; i<=$((num-1)); ++i)); do 
        echo "scale=2;$from+($to-$from)*${i}/$((num-1))" | bc | awk '{printf "%.2f\n", $0}'
    done
}
linspacefromto(){
    from=$1
    to=$2
    num=$3
    # Assume 0 is not written as -0 , will throw errors if this is the case
    # Exit if to < from
    if (( $(echo "$to < $from" | bc -l) ))
    then
        echo "linspacefromto() error: to is smaller than from, exiting"
        exit
    fi
    if (( $(echo "$from < 0" | bc -l) )) && (( $(echo "$to < 0" | bc -l) ))
    then
        # Both from and to negative
        from=$(echo "-1*$from" | bc -l)
        to=$(echo "-1*$to" | bc -l)
        for ((i=0; i<=$((num-1)); ++i))
        do
            echo "scale=2;$from+($to-$from)*${i}/$((num-1))" | bc | awk '{printf "-%.2f\n", $0}'
        done
    elif (( $(echo "$from < 0" | bc -l) ))
    then
        # From is negative
        for ((i=0; i>=-$((num-1)); --i))
        do
            echo "scale=2;$from+(-$to+$from)*${i}/$((num-1))" | bc | awk '{printf "%.2f\n", $0}'
        done
    else
        # Both from and to positive
        for ((i=0; i<=$((num-1)); ++i))
        do
            echo "scale=2;$from+($to-$from)*${i}/$((num-1))" | bc | awk '{printf "%.2f\n", $0}'
        done
    fi
}

# Create arrays of parameters to search
readarray -t disps < <(linspacefromto $mindisp $maxdisp $resdisp)
readarray -t infs < <(linspacefromto $minif $maxif $resif)

# Generate params.txt file for use in each process
chunksize=$(($numsims / $nprocs))
rest=$(($numsims % $nprocs))
currentprocess=1
i=0
infchunk=()
dispchunk=()
iteration=1
for inf in ${infs[*]}; do
    for disp in ${disps[*]}; do
        # Add configuration to chunk arrays of configurations for
        # running on the current process
        infchunk+=($inf)
        dispchunk+=($disp)
        i=$(($i+1))
        #echo "iteration" $iteration
        #iteration=$(($iteration+1))
        # Keep track of which process to work on
        if [[ $(($i % $chunksize)) -eq 0 || $disp == ${disps[-1]} ]]; then
            # Done with current process            
            # Create uniqie arrays containing the chunk of parameters
            infchunk=($(echo "${infchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
            dispchunk=($(echo "${dispchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
            # Create and save the params file for the chunk of configurations
            echo "$(createparamsfile "${dispchunk[*]}" "${infchunk[*]}")" > $outdir/params-${currentprocess}.txt
            #createparamsfile "${dispchunk[*]}" "${infchunk[*]}"
            #echo "----------------"
            # Reset chunk arrays
            infchunk=()
            dispchunk=()
            # Increment process count
            currentprocess=$(($currentprocess + 1))
        fi
    done
done

if [[ ${#infchunk[*]} -gt 0 && ${#dispchunk[*]} -gt 0 ]]; then
    # Create and save the params file for the rest chunk of configurations
    # Create uniqie arrays containing the chunk of parameters
    infchunk=($(echo "${infchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
    dispchunk=($(echo "${dispchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
    #echo "rest configuration"
    echo "$(createparamsfile "${dispchunk[*]}" "${infchunk[*]}")" > $outdir/params-${currentprocess}.txt
    #createparamsfile "${dispchunk[*]}" "${infchunk[*]}"
fi
#exit
k=1
while [[ $k -lt $currentprocess ]]; do
    # Start all processes
    for ((i=$k; i<$(($k + $nprocs)); ++i)); do
        pf=$outdir/params-${i}.txt
        if [[ -f $pf ]]; then
            cmd="bash $scriptdir/run-process.sh $pf $outdir/projections-${i} $inputimg $brainmask $lesionmask $measureimg &"
            eval $cmd
            pids[$i]=$!
        fi
    done
    # Wait for all process to finish
    for pid in ${pids[*]} ; do
        wait $pid
    done
    #
    k=$(($k + $nprocs))
done
# Collect grid search results from cross-correlation assessment
cmd="bash $scriptdir/collect-cc.sh $outdir > $outdir/results-cc.txt"
eval $cmd
