: '
bash run-process.sh params.txt <out dir> <inputimg> <brainmask> <lesionmask> <measureimg>
'

#cancersimdir="/mnt/HDD3TB/code/cancer-sim"

param=$1
mdir=$2

# Input MRI to the simulation
inputimg=$3
brainmask=$4
lesionmask=$5

# MRI to assess the simulation (second time-point MRI)
measureimg=$6

bash $cancersimdir/generate-models.sh $param $inputimg $lesionmask $brainmask $mdir 1

bash $cancersimdir/compute-cc-models.sh $measureimg $mdir > $mdir/correlations.txt
