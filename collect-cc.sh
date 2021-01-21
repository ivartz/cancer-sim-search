: '
bash collect-cc
'

outdir="/mnt/HDD3TB/derivatives/cancer-sim-example/large-grid-search"

nmodels=$(ls -d $outdir/*/ | wc -l)

for ((i=1;i<=$nmodels;++i)); do 
    md="$outdir/models-$i"
    p=$md/params-all.txt
    c=$md/correlations.txt
    num=$(cat $c | wc -l)
    if [[ $i -eq 1 ]]; then
        printf "%s\t%s\t%s\n" "disp" "idf" "cc"
    fi
    for ((j=0;j<$num;++j)); do
        dispcmd="sed -n $(($j+2))p $p | cut -d $'\t' -f 2"
        bccmd="sed -n $(($j+2))p $p | cut -d $'\t' -f 4"
        cccmd="sed -n $(($j+1))p $c"
        printf "%s\t%s\t%s\n" "$(eval $dispcmd)" "$(eval $bccmd)" "$(eval $cccmd)"
    done
done
