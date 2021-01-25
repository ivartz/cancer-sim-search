: '
bash grid-search-2d.sh
'

scriptdir=$(dirname $0)

# Output directory of models.
# Also used to save params.txt files for use in each thread
#paramsdir=$1
outdir="/mnt/HDD3TB/derivatives/cancer-sim-example/large-grid-search"

# Number of CPU threads to use. Will create an additional thread if 
# necessary for processing remaining data
nprocs=$(($(nproc)/2))
#nprocs=5

# 2D grid search space

# Min and max displacement magnitude and resolution
mindisp=1
maxdisp=7
resdisp=5

# Min and max brain coverage x and resolution
# x=1-y, y element [0,1]; 0=largest brain coverage
minbc=0
maxbc=0.4
resbc=5

numsims=$(($resdisp * $resbc))

if [[ $nprocs -gt $numsims ]]; then
    echo "The number of configurations to search is smaller than the number of threads specified. Setting numbers of threads to use as the number of configurations"
    nprocs=$numsims
fi

echo "Number of models to search:" $numsims

createparamsfile(){
    # Create <procs> number of parameter configuration files for independent runs
    disps2=$1
    bcs=$2
    IFS="=" # Internal Field Separator, used for word splitting
    while read -r k v; do
        if [[ $k = "displacement" ]]; then
            echo ${k}=$disps2
        elif [[ $k = "intensity_decay_fraction" ]]; then
            echo ${k}=$bcs
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

linspacefromto(){
    from=$1
    to=$2
    num=$3
    for ((i=0; i<=$((num-1)); ++i)); do 
        echo "scale=2;$from+($to-$from)*${i}/$((num-1))" | bc | awk '{printf "%.2f\n", $0}'
    done
}

# Create arrays of parameters to search
readarray -t disps < <(linspacefromto $mindisp $maxdisp $resdisp)
readarray -t bcovs < <(linspacefromto $minbc $maxbc $resbc)

# Generate params.txt file for use in each thread
chunksize=$(($numsims / $nprocs))
rest=$(($numsims % $nprocs))
currentthread=1
i=0
bcovchunk=()
dispchunk=()
iteration=1
for bcov in ${bcovs[*]}; do
    for disp in ${disps[*]}; do
        # Add configuration to chunk arrays of configurations for
        # running on the current thread
        bcovchunk+=($bcov)
        dispchunk+=($disp)
        i=$(($i+1))
        #echo "iteration" $iteration
        #iteration=$(($iteration+1))
        # Keep track of which thread to work on
        if [[ $(($i % $chunksize)) -eq 0 || $disp == ${disps[-1]} ]]; then
            # Done with current thread            
            # Create uniqie arrays containing the chunk of parameters
            bcovchunk=($(echo "${bcovchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
            dispchunk=($(echo "${dispchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
            # Create and save the params file for the chunk of configurations
            echo "$(createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}")" > $outdir/params-${currentthread}.txt
            #createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}"
            #echo "----------------"
            # Reset chunk arrays
            bcovchunk=()
            dispchunk=()
            # Increment thread count
            currentthread=$(($currentthread + 1))
        fi
    done
done

if [[ ${#bcovchunk[*]} -gt 0 && ${#dispchunk[*]} -gt 0 ]]; then
    # Create and save the params file for the rest chunk of configurations
    # Create uniqie arrays containing the chunk of parameters
    bcovchunk=($(echo "${bcovchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
    dispchunk=($(echo "${dispchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
    #echo "rest configuration"
    echo "$(createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}")" > $outdir/params-${currentthread}.txt
    #createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}"
fi
exit
k=1
while [[ $k -lt $currentthread ]]; do
    # Start all processes
    for ((i=$k; i<$(($k + $nprocs)); ++i)); do
        pf=$outdir/params-${i}.txt
        if [[ -f $pf ]]; then
            cmd="bash $scriptdir/run-thread.sh $pf $outdir/models-${i} &"
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
# Collect grid results from cross-correlation assessment
cmd="bash $scriptdir/collect-cc.sh > $outdir/results-cc.txt"
eval $cmd
