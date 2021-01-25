: '
bash grid-search-3d.sh
'

scriptdir=$(dirname $0)

# Output directory of models.
# Also used to save params.txt files for use in each thread
#paramsdir=$1
outdir="/mnt/HDD3TB/derivatives/cancer-sim-example/large-grid-search"

# Number of CPU threads to use. Will create an additional thread if 
# necessary for processing remaining data
nprocs=$(($(nproc)/2))
#nprocs=6

# 3D grid search space (two first dimensions make up the first spatial dimension in the 3D grid search)
# Perlin max and min resolution
presmin=0.03
presmax=0.05
presres=2

# Perlin noise maximum magntude (in absolute vector magnitude value)
pabsmin=0
pabsmax=0.6
pabsres=2

# Min and max brain coverage x and resolution
# x=1-y, y element [0,1]; 0=largest brain coverage
minbc=0.1
maxbc=1
resbc=2

# Min and max displacement magnitude and resolution
mindisp=3
maxdisp=8
resdisp=2

if [[ $(echo "$pabsmin == 0" | bc -l) ]]; then
    numsims=$(($presres * ($pabsres-1) * $resbc * $resdisp + $resbc * $resdisp))
else
    numsims=$(($presres * $pabsres * $resbc * $resdisp))
fi

if [[ $nprocs -gt $numsims ]]; then
    echo "The number of configurations to search is smaller than the number of threads specified. Setting numbers of threads to use as the number of configurations"
    nprocs=$numsims
fi

echo "Number of models to search:" $numsims

createparamsfile(){
    # Create <procs> number of parameter configuration files for independent runs
    # Bash functions are not global scope, apparently, so don't re-use names
    # used outside of the function as they will be modified
    disps2=$1
    bcs=$2
    press2=$3
    pabss2=$4
    IFS="=" # Internal Field Separator, used for word splitting
    while read -r k v; do
        if [[ $k = "displacement" ]]; then
            echo ${k}=$disps2
        elif [[ $k = "intensity_decay_fraction" ]]; then
            echo ${k}=$bcs
        elif [[ $k = "perlin_noise_res" ]]; then
            echo ${k}=$press2
        elif [[ $k = "perlin_noise_abs_max" ]]; then
            echo ${k}=$pabss2
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
perlin_noise_res=
perlin_noise_abs_max='
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
readarray -t press < <(linspacefromto $presmin $presmax $presres)
readarray -t pabss < <(linspacefromto $pabsmin $pabsmax $pabsres)
readarray -t bcovs < <(linspacefromto $minbc $maxbc $resbc)
readarray -t disps < <(linspacefromto $mindisp $maxdisp $resdisp)

# Generate params.txt file for use in each thread
chunksize=$(($numsims / $nprocs))
rest=$(($numsims % $nprocs))
currentthread=1
i=0
pabsschunk=()
presschunk=()
bcovchunk=()
dispchunk=()
iteration=1
for pabs in ${pabss[*]}; do
    if (( $(echo "$pabs == 0" | bc -l) )); then
        pressel=(${press[0]})
    else
        pressel=(${press[*]})
    fi
    for pres in ${pressel[*]}; do
        for bcov in ${bcovs[*]}; do
            for disp in ${disps[*]}; do
                # Add configuration to chunk arrays of configurations for
                # running on the current thread
                pabsschunk+=($pabs)
                presschunk+=($pres)
                bcovchunk+=($bcov)
                dispchunk+=($disp)
                i=$(($i+1))
                #echo "iteration" $iteration
                #iteration=$(($iteration+1))
                # Keep track of which thread to work on
                if [[ $(($i % $chunksize)) -eq 0 || $disp == ${disps[-1]} || $bcov == ${bcovs[-1]} || $pres == ${pressel[-1]} || $pabs == ${pabss[-1]} ]]; then
                    # Done with current thread
                    # Create uniqie arrays containing the chunk of parameters
                    # Reduce parameters in outer loops to not have duplicates
                    pabsschunk=($(echo "${pabsschunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
                    presschunk=($(echo "${presschunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
                    bcovchunk=($(echo "${bcovchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
                    dispchunk=($(echo "${dispchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
                    # Create and save the params file for the chunk of configurations
                    echo "$(createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}" "${presschunk[*]}" "${pabsschunk[*]}")" > $outdir/params-${currentthread}.txt
                    #createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}" "${presschunk[*]}" "${pabsschunk[*]}"
                    #echo "----------------"
                    # Reset chunk arrays
                    pabsschunk=()
                    presschunk=()
                    bcovchunk=()
                    dispchunk=()
                    # Increment thread count
                    currentthread=$(($currentthread + 1))
                fi
            done
        done
    done
done

if [[ ${#pabsschunk[*]} -gt 0 && ${#presschunk[*]} -gt 0 && ${#bcovchunk[*]} -gt 0 && ${#dispchunk[*]} -gt 0 ]]; then
    # Create and save the params file for the rest chunk of configurations
    # Create uniqie arrays containing the chunk of parameters
    # Reduce parameters in outer loops to not have duplicates
    pabsschunk=($(echo "${pabsschunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
    presschunk=($(echo "${presschunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
    bcovchunk=($(echo "${bcovchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
    dispchunk=($(echo "${dispchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
    #echo "rest configuration"
    echo "$(createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}" "${presschunk[*]}" "${pabsschunk[*]}")" > $outdir/params-${currentthread}.txt
    #createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}" "${pabsschunk[*]}" "${presschunk[*]}"
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
