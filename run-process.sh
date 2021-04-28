: '
bash run-process.sh params.txt <out dir> <inputimg> <brainmask> <tumormask> <measureimg>
'

#cancersimdir="/mnt/HDD3TB/code/cancer-sim"

param=$1
mdir=$2

# Input MRI to the simulation
inputimg=$3
brainmask=$4
tumormask=$5

# MRI to assess the simulation (second time-point MRI)
measureimg=$6

bash $cancersimdir/generate-models.sh $param $inputimg $tumormask $brainmask $mdir 1

bash $cancersimdir/compute-cc-models.sh $measureimg $mdir > $mdir/correlations.txt
