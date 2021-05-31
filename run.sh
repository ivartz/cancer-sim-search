: '
Run grid search on longitudinal BIDS-like dataset
'
dataset=/home/$USER/bidsdir/derivatives/tests/boston-in
outdir=/home/$USER/bidsdir/derivatives/tests/boston-out

# The name of the nii.gz file to warp in each time instance
img=T2

# The name of the nii.gz file to use as model generating mask for each time instance
lesion=ContrastEnhancedMask

# In addition to img and lesion, requires BrainExtractionMask.nii.gz within each ses folders

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

# Grid search on the patients
for patient in ${patients[*]}
do 
    patientfolder=$(basename $patient)
    cmd="bash $cancersimsearchdir/longitudinal-fit.sh ${patient%/} $outdir/$patientfolder $ndims $lesion $img"
    eval $cmd
done

# Collect final results
cmd="bash $cancersimsearchdir/collect-fit-all.sh $dataset $outdir > $outdir/results.txt"
eval $cmd
