: '
Fit the cancer-sim model on longitudinal BIDS-like dataset
'
dataset=/home/$USER/bidsdir/derivatives/lidia
outdir=/home/$USER/bidsdir/derivatives/lidia-fit

# The name of the nii.gz file to warp in each time instance
img=flair

# The name of the nii.gz file to use as model generating mask for each time instance
lesion=seg

# The integer value of the lesion segmentation inside the $lesion file to use in modeling
lesionval=2

# The name of nii.gz file containing the brain extraction mask for each time instance
bmask=bmask

: '
Grid search dimensions:
2: Maximum tissue displacement, tumor infiltration
3: Maximum tissue displacement, tumor infiltration and growth irregularity
'
ndims=2

# Make an array of patient directories
readarray -t patients < <(ls -d $dataset/*/ | sort)

echo "Patients found:"
echo ${patients[*]}
read -p "Press key to continue..."

# Data augmentation on the patients
for patient in ${patients[*]}
do 
    patientfolder=$(basename $patient)
    # Fitting the model to each time point examination interval
    cmd="bash $cancersimsearchdir/longitudinal-fit.sh ${patient%/} $outdir/$patientfolder $ndims $lesion $lesionval $bmask $img"
    eval $cmd
done
: '
# Collect final results
cmd="bash $cancersimsearchdir/collect-fit-all.sh $dataset $outdir > $outdir/results.txt"
eval $cmd
'
