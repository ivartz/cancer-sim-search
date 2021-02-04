cancersimdir="/mnt/HDD3TB/code/cancer-sim"
cancersimsearchdir="/mnt/HDD3TB/code/cancer-sim-search"
dataset="/mnt/HDD3TB/derivatives/SAILOR_PROCESSED_MNI/001-QUUyOkRb"
od="/mnt/HDD3TB/derivatives/cancer-sim-search-SAILOR_PROCESSED_MNI-001-QUUyOkRb-longitudinal-3d"



# Longitudinal grid search

for i in {1..5}; do first=$(printf %02d $i); second=$(printf %02d $((i+1))); cmd="bash $cancersimsearchdir/search-timestep.sh $dataset $first $second $od/${first}_${second}"; eval $cmd; echo -- ; done

# Find most fit models using regularization technique on displacement magnitude and brain coverage


# see highest-mag-thr.py for cutoff parameter used




cmd="bash $cancersimsearchdir/showfit.sh $od"
eval $cmd

# Re-run with best parameters


for i in {1..5}; do first=$(printf %02d $i); second=$(printf %02d $((i+1))); of="$od/${first}_${second}-fit"; if [[ -d $of ]]; then cmd="rm -rd $of"; fi; eval $cmd; cmd="bash $cancersimdir/generate-models.sh $od/params-fit-$(printf %03d $i).txt $dataset/$first/T1c.nii.gz $dataset/$first/Segmentation.nii.gz $dataset/$first/BrainExtractionMask.nii.gz $of 0"; eval $cmd; echo -- ; done


# Visualize more
bash $cancersimsearchdir/showfit-best-all.sh $od $dataset
