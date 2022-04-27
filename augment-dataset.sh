: '
Run augmentations on longitudinal BIDS-like dataset
bash augment-dataset.sh
'
dataset=/home/$USER/bidsdir/derivatives/lidia
outdir=/home/$USER/bidsdir/derivatives/lidia-aug-2

# The name of the nii.gz files to warp in each time instance
mris=(flair t1 t1c t2)

# The name of the nii.gz file to use as model generating mask for each time instance
lesion=seg

# The integer value of the lesion segmentation inside the $lesion file to use in modeling, or 'nonzero'
lesionval=nonzero

# The name of nii.gz file containing the brain extraction mask for each time instance
bmask=bmask

: '
Grid search dimensions:
2: Maximum tissue displacement, tumor infiltration
3: Maximum tissue displacement, tumor infiltration and growth irregularity
'
ndims=2

# Minimal output: Only output final model displacement and deformed mris and lesion mask
minimal=1

# Make an array of patient directories
readarray -t patients < <(ls -d $dataset/*/ | sort -V)

echo "Patients found:"
echo ${patients[*]}
read -p "Press key to continue..."

# Data augmentation on the patients
for patient in ${patients[*]}
do 
    patientfolder=$(basename $patient)
    # Data augmentations for each time point exam
    cmd="bash $cancersimsearchdir/longitudinal-augment.sh ${patient%/} $outdir/$patientfolder $ndims $lesion $lesionval $bmask '${mris[*]}' $minimal"
    eval $cmd
done

