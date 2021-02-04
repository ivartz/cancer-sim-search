: '
bash grid-search-3d.sh <inputimg> <brainmask> <tumormask> <measureimg> <outdir>

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
#nprocs=6

# 3D grid search space (two first dimensions make up the first spatial dimension in the 3D grid search)

# Perlin max and min resolution
presmin=0.02
presmax=0.1
presres=3

# Perlin noise maximum magntude (in absolute vector magnitude value)
pabsmin=0
pabsmax=1
pabsres=3

# Min and max brain coverage x and resolution
# x=1-y, y element [0,1]; 0=largest brain coverage
minbc=0.01
maxbc=0.4
resbc=6

# Min and max displacement magnitude and resolution
mindisp=2
maxdisp=9
resdisp=6

if [[ $(echo "$pabsmin == 0" | bc -l) ]]; then
    numsims=$(($presres * ($pabsres-1) * $resbc * $resdisp + $resbc * $resdisp))
else
    numsims=$(($presres * $pabsres * $resbc * $resdisp))
fi

if [[ $nprocs -gt $numsims ]]; then
    echo "The number of configurations to search is smaller than the number of processes specified. Setting numbers of processes to use as the number of configurations"
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

# Generate params.txt file for use in each process
chunksize=$(($numsims / $nprocs))
rest=$(($numsims % $nprocs))
currentprocess=1
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
                # running on the current process
                pabsschunk+=($pabs)
                presschunk+=($pres)
                bcovchunk+=($bcov)
                dispchunk+=($disp)
                i=$(($i+1))
                #echo "iteration" $iteration
                #iteration=$(($iteration+1))
                # Keep track of which process to work on
                if [[ $(($i % $chunksize)) -eq 0 || $disp == ${disps[-1]} || $bcov == ${bcovs[-1]} || $pres == ${pressel[-1]} || $pabs == ${pabss[-1]} ]]; then
                    # Done with current process
                    # Create uniqie arrays containing the chunk of parameters
                    # Reduce parameters in outer loops to not have duplicates
                    pabsschunk=($(echo "${pabsschunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
                    presschunk=($(echo "${presschunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
                    bcovchunk=($(echo "${bcovchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
                    dispchunk=($(echo "${dispchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
                    # Create and save the params file for the chunk of configurations
                    echo "$(createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}" "${presschunk[*]}" "${pabsschunk[*]}")" > $outdir/params-${currentprocess}.txt
                    #createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}" "${presschunk[*]}" "${pabsschunk[*]}"
                    #echo "----------------"
                    # Reset chunk arrays
                    pabsschunk=()
                    presschunk=()
                    bcovchunk=()
                    dispchunk=()
                    # Increment process count
                    currentprocess=$(($currentprocess + 1))
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
    echo "$(createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}" "${presschunk[*]}" "${pabsschunk[*]}")" > $outdir/params-${currentprocess}.txt
    #createparamsfile "${dispchunk[*]}" "${bcovchunk[*]}" "${pabsschunk[*]}" "${presschunk[*]}"
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
