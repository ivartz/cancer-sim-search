: '
bash longitudinal-fit.sh <patient data in> <patient data out>
'

#cancersimdir="/mnt/HDD3TB/code/cancer-sim"
#cancersimsearchdir="/mnt/HDD3TB/code/cancer-sim-search"
#patientdata="/mnt/HDD3TB/derivatives/SAILOR_PROCESSED_MNI/001-QUUyOkRb"

patientdata=$1

#od="/home/ivar/Documents/cancer-sim-search-SAILOR_PROCESSED_MNI-001-QUUyOkRb-longitudinal-2d-2"

od=$2

: '
Grid search dimensions:
2: Maximum tissue displacement, tumor infiltration
3: Maximum tissue displacement, tumor infiltration and growth irregularity
'
#dimensions=2
dimensions=$3

# Name of lesion mask to use
lesion=$4

# Set number of processes to use as half of the available cpu threads
nprocs=$(($(nproc)/2))

# Longitudinal grid search

numintervals=$(($(ls -d ${patientdata}/*/ | wc -l )-1))
#numintervals=1
for ((i=1; i<=$numintervals; ++i))
do
    first=$(printf ses-%02d $(($i+1)))
    second=$(printf ses-%02d $i)
    cmd="bash $cancersimsearchdir/search-timestep.sh $patientdata $first $second $od/${first}_${second} $dimensions $lesion"
    eval $cmd
    echo --
done

# Find most fit models using regularization technique on displacement magnitude and brain coverage

# see highest-mag-thr.py for cutoff parameter used

cmd="bash $cancersimsearchdir/mostfit.sh $od"
eval $cmd

# Re-run with best parameters

k=1
while [[ $k -lt $(($numintervals+1)) ]]
do
    # Start all processes
    for ((i=$k; i<$(($k + $nprocs)); ++i))
    do
        first=$(printf ses-%02d $(($i+1)))
        second=$(printf ses-%02d $i)
        of="$od/${first}_${second}-fit"
        if [[ -d $patientdata/$first ]]
        then
            cmd="bash $cancersimdir/generate-models.sh $od/params-fit-$(printf %03d $i).txt $patientdata/$first/T1c.nii.gz $patientdata/$first/$lesion.nii.gz $patientdata/$first/BrainExtractionMask.nii.gz $of 0 &"
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
#: '
# Delete non-optimal simulations
for d in $(ls -d $od/*/ | sort | grep -v fit)
do
    r=${d}results.txt
    cmd="mv $r $(dirname $d)/$(basename $d)-results.txt"
    eval $cmd    
    cmd="rm -rd $d"
    eval $cmd
done
#'
# Visualize more
cmd="bash $cancersimsearchdir/mostfit-all.sh $od $patientdata"
eval $cmd

