: '
Run grid search on longitudinal BIDS-like dataset
'
dataset=/home/$USER/bidsdir/derivatives/sailor-coreg
outdir=/home/$USER/bidsdir/derivatives/cancer-sim-search

# The name of the nii.gz file to use as model generating mask
lesion=TumorMask

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
    cmd="bash $cancersimsearchdir/longitudinal-fit.sh ${patient%/} $outdir/$patientfolder $ndims $lesion"
    eval $cmd
done

