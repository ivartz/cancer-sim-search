: '
bash augment-timestep.sh <patient data> <examination (session) folder> <outdir> <grid search dimensions> <lesion> <lesion value> <brain extraction mask> <structural image> <minimal>
'
scriptdir=$(dirname $0)
patientdata=$1
ses=$2
outdir=$3
ndim=$4
lesion=$5
lesionval=$6
bmask=$7
imgname=$8
minimal=$9

img=$patientdata/$ses/$imgname.nii.gz
brainmask=$patientdata/$ses/$bmask.nii.gz
lesionmask=$patientdata/$ses/$lesion.nii.gz

mkdircmd="mkdir -p $outdir"
eval $mkdircmd

cmd="bash $scriptdir/augmentation-grid-search-${ndim}d.sh $img $brainmask $lesionmask $lesionval $outdir $minimal"
eval $cmd

