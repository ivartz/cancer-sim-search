: '
bash search-dataset.sh
'
scriptdir=$(dirname $0)

dataset="/mnt/HDD3TB/derivatives/SAILOR_PROCESSED_MNI"

outdir="/mnt/HDD3TB/derivatives/cancer-sim-search-SAILOR_PROCESSED_MNI-01-02"

readarray -t firstdirs < <(find $dataset -type d -name 01 | sort)
readarray -t seconddirs < <(find $dataset -type d -name 02 | sort)

# Assiming firstd and secondd arrays equal length

numpatients=${#firstdirs[*]}

for ((i=0; i<$numpatients; ++i)); do
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
