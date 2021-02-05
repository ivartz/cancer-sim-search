cancersimdir="/mnt/HDD3TB/code/cancer-sim"
cancersimsearchdir="/mnt/HDD3TB/code/cancer-sim-search"
dataset="/mnt/HDD3TB/derivatives/SAILOR_PROCESSED_MNI/001-QUUyOkRb"


od="/home/ivar/Documents/cancer-sim-search-SAILOR_PROCESSED_MNI-001-QUUyOkRb-longitudinal-2d-2"

# Grid search dimensions
dimension=2

nprocs=$(($(nproc)/2))

# Longitudinal grid search

numintervals=5

for ((i=1; i<=$numintervals; ++i))
do
    first=$(printf %02d $i)
    second=$(printf %02d $((i+1)))
    cmd="bash $cancersimsearchdir/search-timestep.sh $dataset $first $second $od/${first}_${second} $dimension"
    eval $cmd
    echo --
done

# Find most fit models using regularization technique on displacement magnitude and brain coverage

# see highest-mag-thr.py for cutoff parameter used

cmd="bash $cancersimsearchdir/mostfit.sh $od"
eval $cmd

# Re-run with best parameters

k=1
while [[ $k -lt $((numintervals+1)) ]]
do
    # Start all processes
    for ((i=$k; i<$(($k + $nprocs)); ++i))
    do
        first=$(printf %02d $i)
        second=$(printf %02d $((i+1)))
        of="$od/${first}_${second}-fit"
        if [[ -d $dataset/$second ]]
        then
            cmd="bash $cancersimdir/generate-models.sh $od/params-fit-$(printf %03d $i).txt $dataset/$first/T1c.nii.gz $dataset/$first/Segmentation.nii.gz $dataset/$first/BrainExtractionMask.nii.gz $of 0 &"
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
cmd="bash $cancersimsearchdir/mostfit-all.sh $od $dataset"
eval $cmd
