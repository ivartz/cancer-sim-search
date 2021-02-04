: '
bash search-timestep.sh <dataset> <first examination folder> <second examination folder> <outdir>
'
scriptdir=$(dirname $0)

#dataset="/mnt/HDD3TB/derivatives/SAILOR_PROCESSED_MNI"
dataset=$1

#first=$(printf %02d $2)
first=$2

#second=$(printf %02d $3)
second=$3

#outdir="/mnt/HDD3TB/derivatives/cancer-sim-search-SAILOR_PROCESSED_MNI-01-02"
outdir=$4

readarray -t firstdirs < <(find $dataset -type d -name $first | sort)
readarray -t seconddirs < <(find $dataset -type d -name $second | sort)

if [[ ${#firstdirs[*]} -ne ${#seconddirs[*]} ]]
then
    echo "Did not find all matching first and second dirs"
    exit
fi

# Assiming firstd and secondd arrays equal length

numpatients=${#firstdirs[*]}

for ((i=0; i<$numpatients; ++i))
do
    firstdir=${firstdirs[$i]}
    seconddir=${seconddirs[$i]}
    firstimg=$firstdir/T1c.nii.gz
    brainmask=$firstdir/BrainExtractionMask.nii.gz
    tumormask=$firstdir/Segmentation.nii.gz
    secondimg=$seconddir/T1c.nii.gz
    patientoutfolder=$(basename $(dirname $firstdir))
    patientoutdir=$outdir/$patientoutfolder   
    mkdircmd="mkdir -p $patientoutdir"
    eval $mkdircmd
    cmd="bash $scriptdir/grid-search-3d.sh $firstimg $brainmask $tumormask $secondimg $patientoutdir"
    eval $cmd
done

# Collect results
cmd="bash $scriptdir/collect-cc-dataset.sh $outdir > $outdir/results.txt"
eval $cmd
