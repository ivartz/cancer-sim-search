: '
bash run-augmentation-process.sh params.txt <out dir> <inputimg> <brainmask> <lesionmask> <lesionval> <minimalout>
'
param=$1
mdir=$2
inputimgs=($3)
brainmask=$4
lesionmask=$5
lesionval=$6
minimalout=$7

bash $cancersimdir/generate-models.sh $param "${inputimgs[*]}" $lesionmask $lesionval $brainmask $mdir $minimalout

