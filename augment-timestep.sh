: '
bash augment-timestep.sh <patient data> <examination (session) folder> <outdir> <grid search dimensions> <lesion name> <lesion value> <brain extraction mask> <structural images, names> <minimal>
'
scriptdir=$(dirname $0)
patientdata=$1
ses=$2
outdir=$3
ndim=$4
lesionname=$5
lesionval=$6
bmask=$7
imgnames=($8)
minimal=$9

mris=()
for imgname in ${imgnames[*]}
do
    mris+=($patientdata/$ses/$imgname.nii.gz)
done
brainmask=$patientdata/$ses/$bmask.nii.gz
lesionmask=$patientdata/$ses/$lesionname.nii.gz

mkdircmd="mkdir -p $outdir"
eval $mkdircmd

cmd="bash $scriptdir/augmentation-grid-search-${ndim}d.sh '${mris[*]}' $brainmask $lesionmask $lesionval $outdir $minimal"
eval $cmd

cmd="bash $scriptdir/rename-move-augment-files.sh $outdir '${imgnames[*]}' $lesionname"
eval $cmd

cmd="bash $scriptdir/collect-params.sh $outdir > $outdir/parameters.txt"
eval $cmd

cmd="bash $scriptdir/remove-params-dirs.sh $outdir"
eval $cmd

