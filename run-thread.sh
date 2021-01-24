: '
bash run-thread.sh params.txt <out dir>
'
param=$1
mdir=$2
cancersimdir="/mnt/HDD3TB/code/cancer-sim"

# Input MRI to the simulation
inputimg="/mnt/HDD3TB/derivatives/cancer-sim-example/derivatives/1-T1c.nii.gz"
brainmask="/mnt/HDD3TB/derivatives/cancer-sim-example/derivatives/1-brainmask.nii.gz"
tumormask="/mnt/HDD3TB/derivatives/cancer-sim-example/derivatives/1-tumormask.nii.gz"

# MRI to assess the simulation (second time-point MRI)
measureimg="/mnt/HDD3TB/derivatives/cancer-sim-example/derivatives/reg/2-T1c-reg.nii.gz"

bash $cancersimdir/generate-models.sh $param $inputimg $tumormask $brainmask $mdir

bash $cancersimdir/compute-cc-models.sh $measureimg $mdir > $mdir/correlations.txt
