: '
bash prepend-time-step-cc.sh <model projections and cross-correlation assesment output folder>
'
outdir=$1

timestep=$(basename $outdir)
results=$outdir/results-cc.txt
numresults=$(cat $results | wc -l)
for ((j=1; j<=$numresults; ++j))
do
    if [[ $j -eq 1 ]]
    then
        linecmd="sed -n ${j}p $results"
        printf "%s\t%s\n" "timestep" "$(eval $linecmd)"
    fi
    if [[ $j -lt $numresults ]]
    then
        linecmd="sed -n $(($j+1))p $results"
        printf "%s\t%s\n" "$timestep" "$(eval $linecmd)"
    fi
done

