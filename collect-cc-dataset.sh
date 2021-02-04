: '
bash collect-cc-dataset.sh <searched dataset output>

dataset="/mnt/HDD3TB/derivatives/cancer-sim-search-SAILOR_PROCESSED_MNI-01-02"
'
#dataset="/mnt/HDD3TB/derivatives/cancer-sim-search-SAILOR_PROCESSED_MNI-01-02"
dataset=$1

readarray -t patientdirs < <(ls -d $dataset/*/ | sort)

numpatients=${#patientdirs[*]}

for ((i=0; i<$numpatients; ++i)); do
    patientdir=${patientdirs[$i]}
    patientfolder=$(basename $patientdir)
    results=$patientdir/results-cc.txt
    numresults=$(cat $results | wc -l)
    for ((j=1; j<=$numresults; ++j)); do
        if [[ $i -eq 0 && $j -eq 1 ]]; then
            linecmd="sed -n ${j}p $results"
            printf "%s\t%s\n" "patient" "$(eval $linecmd)"
        fi
        if [[ $j -lt $numresults ]]; then
            linecmd="sed -n $(($j+1))p $results"
            printf "%s\t%s\n" "$patientfolder" "$(eval $linecmd)"
        fi
    done
done
