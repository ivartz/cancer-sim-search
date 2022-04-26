: '
bash longitudinal-augment.sh <patient data in> <patient data out> <n dims> <lesion mask> <lesion mask value> <brain mask> <structural image> <minimal>
'
patientdata=$1
od=$2

: '
Grid search dimensions:
2: Maximum tissue displacement, tumor infiltration
3: Maximum tissue displacement, tumor infiltration and growth irregularity
'
dimensions=$3

# Name of lesion mask to use
lesion=$4

# Integer value of the lesion to use
lesionval=$5

# Name of the brain extraction mask to use
bmask=$6

# Name of structural MRI to use
img=$7

minimal=$8

# Set number of processes to use as half of the available cpu threads
nprocs=$(($(nproc)/2))

# Longitudinal grid search data augmentation

numses=$(ls -d ${patientdata}/*/ | wc -l)
for ((i=1; i<=$numses; ++i))
do
    ses=$(printf ses-%02d $i)
    cmd="bash $cancersimsearchdir/augment-timestep.sh $patientdata $ses $od/$ses $dimensions $lesion $lesionval $bmask $img $minimal"
    eval $cmd
    echo --
done

# Collect params
#cmd="bash $cancersimsearchdir/mostfit.sh $od"
#eval $cmd

: '
# Re-run with best parameters

k=1
while [[ $k -lt $(($numintervals+1)) ]]
do
    # Start all processes
    for ((i=$k; i<$(($k + $nprocs)); ++i))
    do
        first=$(printf ses-%02d $i)
        second=$(printf ses-%02d $(($i+1)))
        of="$od/${first}_${second}-fit"
        if [[ -d $patientdata/$second ]]
        then
            cmd="bash $cancersimdir/generate-models.sh $od/params-fit-$(printf %03d $i).txt $patientdata/$first/$img.nii.gz $patientdata/$first/$lesion.nii.gz $patientdata/$first/BrainExtractionMask.nii.gz $of 0 &"
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

# Delete non-optimal simulations
for d in $(ls -d $od/*/ | sort | grep -v fit)
do
    r=${d}results.txt
    cmd="mv $r $(dirname $d)/$(basename $d)-results.txt"
    eval $cmd    
    cmd="rm -rd $d"
    eval $cmd
done

# Visualize more
cmd="bash $cancersimsearchdir/mostfit-all.sh $od $patientdata $lesion $img"
eval $cmd
'
