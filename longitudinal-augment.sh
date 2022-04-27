: '
bash longitudinal-augment.sh <patient data in> <patient data out> <n dims> <lesion mask> <lesion mask value> <brain mask> <structural image> <minimal>
'
patientdata=$1
od=$2

: '
Grid search dimensions:
2: Maximum tissue displacement, tumor infiltration
3: Maximum tissue displacement, tumor infiltration and growth irregularity
'
dimensions=$3

# Name of lesion mask to use
lesion=$4

# Integer value of the lesion to use
lesionval=$5

# Name of the brain extraction mask to use
bmask=$6

# Name of structural MRI to use
mris=($7)

minimal=$8

# Set number of processes to use as half of the available cpu threads
nprocs=$(($(nproc)/2))

# Longitudinal grid search data augmentation

numses=$(ls -d ${patientdata}/*/ | wc -l)
for ((i=1; i<=$numses; ++i))
do
    ses=$(printf ses-%02d $i)
    cmd="bash $cancersimsearchdir/augment-timestep.sh $patientdata $ses $od/$ses $dimensions $lesion $lesionval $bmask '${mris[*]}' $minimal"
    eval $cmd
    echo --
done

