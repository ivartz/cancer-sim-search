: '
bash search-timestep.sh <patient data> <first examination folder> <second examination folder> <outdir> <grid search dimensions>
'
scriptdir=$(dirname $0)
patientdata=$1
first=$2
second=$3
outdir=$4
ndim=$5

firstimg=$patientdata/$first/T1c.nii.gz
brainmask=$patientdata/$first/BrainExtractionMask.nii.gz
tumormask=$patientdata/$first/TumorMask.nii.gz
secondimg=$patientdata/$second/T1c.nii.gz

mkdircmd="mkdir -p $outdir"
eval $mkdircmd

cmd="bash $scriptdir/grid-search-${ndim}d.sh $firstimg $brainmask $tumormask $secondimg $outdir"
eval $cmd

# Prepend time step to all grid search cross-correlation results in a new file
cmd="bash $scriptdir/prepend-time-step-cc.sh $outdir > $outdir/results.txt"
eval $cmd
