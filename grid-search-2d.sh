: '
bash grid-search-2d.sh <inputimg> <brainmask> <tumormask> <measureimg> <outdir>

inputimg="/mnt/HDD3TB/derivatives/cancer-sim-example/derivatives/1-T1c.nii.gz"
brainmask="/mnt/HDD3TB/derivatives/cancer-sim-example/derivatives/1-brainmask.nii.gz"
tumormask="/mnt/HDD3TB/derivatives/cancer-sim-example/derivatives/1-tumormask.nii.gz"
measureimg="/mnt/HDD3TB/derivatives/cancer-sim-example/derivatives/reg/2-T1c-reg.nii.gz"
# Output directory of models.
# Also used to save params.txt files for use in each process
outdir="/mnt/HDD3TB/derivatives/cancer-sim-example/large-grid-search"
'
scriptdir=$(dirname $0)

inputimg=$1
brainmask=$2
tumormask=$3
measureimg=$4
# Output directory of models.
# Also used to save params.txt files for use in each process
outdir=$5

# Number of CPU processes to use. Will create an additional process if 
# necessary for processing remaining data
nprocs=$(($(nproc)/2))
#nprocs=2

# 2D grid search space

# Min and max brain coverage x and resolution
# x=1-y, y element [0,1]; 0=largest brain coverage
minbc=0.01
maxbc=0.7
resbc=8

# Min and max displacement magnitude and resolution
mindisp=2
maxdisp=9
resdisp=6

numsims=$(($resdisp * $resbc))

if [[ $nprocs -gt $numsims ]]; then
    echo "The number of configurations to search is smaller than the number of processes specified. Setting numbers of processes to use as the number of configurations"
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

# Generate params.txt file for use in each process
chunksize=$(($numsims / $nprocs))
rest=$(($numsims % $nprocs))
currentprocess=1
i=0
bcovchunk=()
dispchunk=()
iteration=1
for bcov in ${bcovs[*]}; do
    for disp in ${disps[*]}; do
        # Add configuration to chunk arrays of configurations for
        # running on the current process
        bcovchunk+=($bcov)
        dispchunk+=($disp)
        i=$(($i+1))
        #echo "iteration" $iteration
        #iteration=$(($iteration+1))
        # Keep track of which process to work on
        if [[ $(($i % $chunksize)) -eq 0 || $disp == ${disps[-1]} ]]; then
            # Done with current process            
            # Create uniqie arrays containing the chunk of parameters
            bcovchunk=($(echo "${bcovchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
            dispchunk=($(echo "${dispchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
            # Create and save the params file for the chunk of configurations
            echo "$(createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}")" > $outdir/params-${currentprocess}.txt
            #createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}"
            #echo "----------------"
            # Reset chunk arrays
            bcovchunk=()
            dispchunk=()
            # Increment process count
            currentprocess=$(($currentprocess + 1))
        fi
    done
done

if [[ ${#bcovchunk[*]} -gt 0 && ${#dispchunk[*]} -gt 0 ]]; then
    # Create and save the params file for the rest chunk of configurations
    # Create uniqie arrays containing the chunk of parameters
    bcovchunk=($(echo "${bcovchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
    dispchunk=($(echo "${dispchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
    #echo "rest configuration"
    echo "$(createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}")" > $outdir/params-${currentprocess}.txt
    #createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}"
fi
#exit
k=1
while [[ $k -lt $currentprocess ]]; do
    # Start all processes
    for ((i=$k; i<$(($k + $nprocs)); ++i)); do
        pf=$outdir/params-${i}.txt
        if [[ -f $pf ]]; then
            cmd="bash $scriptdir/run-process.sh $pf $outdir/models-${i} $inputimg $brainmask $tumormask $measureimg &"
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
cmd="bash $scriptdir/collect-cc.sh $outdir > $outdir/results-cc.txt"
eval $cmd
