: '
bash augmentation-grid-search-3d.sh <inputimgs> <brainmask> <lesionmask> <lesionval> <outdir> <minimalout>
'
scriptdir=$(dirname $0)

inputimgs=($1)
brainmask=$2
lesionmask=$3
lesionval=$4
# Output directory of model augmentations
# Also used to save params.txt files for use in each process
outdir=$5
minimal=$6

# Number of CPU processes to use. Will create an additional process if 
# necessary for processing remaining data
nprocs=$(($(nproc)/2))

# 3D grid search space (last two dimensions make up the first spatial dimension in the 3D grid search)

# Min and max tumor infiltration x and resolution
# x=1-y, y element [0,1]; 0=largest brain coverage
minif=0
maxif=1
resif=5

# Min and max displacement magnitude and resolution
mindisp=-10
maxdisp=10
resdisp=20

# Perlin max and min resolution
presmin=0.05
presmax=0.1
presres=3

# Perlin noise maximum magntude (in absolute vector magnitude value)
pabsmin=0
#pabsmax=$(echo "0.5*$maxdisp" | bc -l)
pabsmax=0.6
pabsres=2

if [[ $(echo "$pabsmin == 0" | bc -l) ]]; then
    numsims=$(($presres * ($pabsres-1) * $resif * $resdisp + $resif * $resdisp))
else
    numsims=$(($presres * $pabsres * $resif * $resdisp))
fi

if [[ $nprocs -gt $numsims ]]; then
    echo "The number of configurations to search is smaller than the number of processes specified. Setting numbers of processes to use as the number of configurations"
    nprocs=$numsims
fi

echo "Number of augmentations:" $numsims

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
readarray -t press < <(linspacefromto $presmin $presmax $presres)
readarray -t pabss < <(linspacefromto $pabsmin $pabsmax $pabsres)
readarray -t infs < <(linspacefromto $minif $maxif $resif)
readarray -t disps < <(linspacefromto $mindisp $maxdisp $resdisp)

# Generate params.txt file for use in each process
chunksize=$(($numsims / $nprocs))
rest=$(($numsims % $nprocs))
currentprocess=1
i=0
pabsschunk=()
presschunk=()
infchunk=()
dispchunk=()
iteration=1
for pabs in ${pabss[*]}; do
    if (( $(echo "$pabs == 0" | bc -l) )); then
        pressel=(${press[0]})
    else
        pressel=(${press[*]})
    fi
    for pres in ${pressel[*]}; do
        for inf in ${infs[*]}; do
            for disp in ${disps[*]}; do
                # Add configuration to chunk arrays of configurations for
                # running on the current process
                pabsschunk+=($pabs)
                presschunk+=($pres)
                infchunk+=($inf)
                dispchunk+=($disp)
                i=$(($i+1))
                #echo "iteration" $iteration
                #iteration=$(($iteration+1))
                # Keep track of which process to work on
                if [[ $(($i % $chunksize)) -eq 0 || $disp == ${disps[-1]} || $inf == ${infs[-1]} || $pres == ${pressel[-1]} || $pabs == ${pabss[-1]} ]]; then
                    # Done with current process
                    # Create uniqie arrays containing the chunk of parameters
                    # Reduce parameters in outer loops to not have duplicates
                    pabsschunk=($(echo "${pabsschunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
                    presschunk=($(echo "${presschunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
                    infchunk=($(echo "${infchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
                    dispchunk=($(echo "${dispchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
                    # Create and save the params file for the chunk of configurations
                    echo "$(createparamsfile "${dispchunk[*]}" "${infchunk[*]}" "${presschunk[*]}" "${pabsschunk[*]}")" > $outdir/params-${currentprocess}.txt
                    #createparamsfile "${dispchunk[*]}" "${infchunk[*]}" "${presschunk[*]}" "${pabsschunk[*]}"
                    #echo "----------------"
                    # Reset chunk arrays
                    pabsschunk=()
                    presschunk=()
                    infchunk=()
                    dispchunk=()
                    # Increment process count
                    currentprocess=$(($currentprocess + 1))
                fi
            done
        done
    done
done

if [[ ${#pabsschunk[*]} -gt 0 && ${#presschunk[*]} -gt 0 && ${#infchunk[*]} -gt 0 && ${#dispchunk[*]} -gt 0 ]]; then
    # Create and save the params file for the rest chunk of configurations
    # Create uniqie arrays containing the chunk of parameters
    # Reduce parameters in outer loops to not have duplicates
    pabsschunk=($(echo "${pabsschunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
    presschunk=($(echo "${presschunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
    infchunk=($(echo "${infchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
    dispchunk=($(echo "${dispchunk[@]}" | tr " " "\n" | awk '!x[$0]++' | tr "\n" " "))
    #echo "rest configuration"
    echo "$(createparamsfile "${dispchunk[*]}" "${infchunk[*]}" "${presschunk[*]}" "${pabsschunk[*]}")" > $outdir/params-${currentprocess}.txt
    #createparamsfile "${dispchunk[*]}" "${infchunk[*]}" "${pabsschunk[*]}" "${presschunk[*]}"
fi

k=1
while [[ $k -lt $currentprocess ]]; do
    # Start all processes
    for ((i=$k; i<$(($k + $nprocs)); ++i)); do
        pf=$outdir/params-${i}.txt
        if [[ -f $pf ]]; then
            cmd="bash $scriptdir/run-augmentation-process.sh $pf $outdir/augs-${i} '${inputimgs[*]}' $brainmask $lesionmask $lesionval $minimal &"
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

