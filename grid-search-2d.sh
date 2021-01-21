: '
bash grid-search-2d.sh
'

# Output directory of models.
# Also used to save params.txt files for use in each thread
#paramsdir=$1
outdir="/mnt/HDD3TB/derivatives/cancer-sim-example/large-grid-search"

# Number of CPU threads to use. Will create an additional thread if 
# necessary for processing remaining data
nthreads=$(($(nproc)/2))

# 2D grid search space

# Min and max displacement magnitude and resolution
mindisp=1
maxdisp=6
resdisp=4

# Min and max brain coverage x and resolution
# x=1-y, y element [0,1]; 0=largest brain coverage
minbc=0
maxbc=1
resbc=2

numsims=$(($resdisp * $resbc))

if [[ $nthreads -gt $numsims ]]; then
    echo "The number of configurations to search is smaller than the number of threads specified. Please increase the number of configurations or decrease the number of threads"
    exit
fi

createparamsfile(){
    # Create <procs> number of parameter configuration files for independent runs
    disps=$1
    bcs=$2

    IFS="=" # Internal Field Separator, used for word splitting
    while read -r k v; do
        if [[ $k = "displacement" ]]; then
            echo ${k}=$disps
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
chunksize=$(($numsims / $nthreads))
currentthread=1
i=0
dispchunk=()
bcovchunk=()
for disp in ${disps[*]}; do
    for bcov in ${bcovs[*]}; do
        # Keep track of which thread to work on
        if [[ $i -gt 0 ]]; then
            if [[ $(($i % $chunksize)) -eq 0 ]]; then
                # Done with current thread
                # Create and save the params file for the chunk of configurations
                echo "$(createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}")" > $outdir/params-${currentthread}.txt
                # Reset chunk arrays
                dispchunk=()
                bcovchunk=()
                # Increment thread count
                currentthread=$(($currentthread + 1))
            fi
        fi
        # Add configuration to chunk arrays of configurations for
        # running on the current thread
        dispchunk+=($disp)
        bcovchunk+=($bcov)
        i=$(($i+1))
    done
done
# Create and save the params file for the rest chunk of configurations
#echo "rest configuration"
echo "$(createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}")" > $outdir/params-${currentthread}.txt

# Start all threads in parallel
for ((i=1; i<=$currentthread; ++i)); do
    cmd="bash run-thread.sh $outdir/params-${i}.txt $outdir/models-${i} &"
    echo $cmd
done
