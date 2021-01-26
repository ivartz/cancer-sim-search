: '
bash collect-cc
'

outdir=$1

nmodelparts=$(ls -d $outdir/*/ | wc -l)

for ((i=1;i<=$nmodelparts;++i)); do
    if [[ $i -eq 1 ]]; then
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "part" "idx" "disp" "idf" "pres" "pabs" "cc"
    fi
    mp="$outdir/models-$i"
    c=$mp/correlations.txt
    readarray -t paramsarr < <(find $mp -type f -name params.txt | sort)
    j=0
    for params in ${paramsarr[*]}; do
        IFS="="
        while read -r param values; do
            readarray -d " " $param < <(echo -n $values)
        done < $params
        for disp in ${displacement[*]}; do
            bccmd="echo ${intensity_decay_fraction[0]}"
            prescmd="echo ${perlin_noise_res[0]}"
            pabscmd="echo ${perlin_noise_abs_max[0]}"
            cccmd="sed -n $(($j+1))p $c"
            printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$i" "$(($j+1))" "$disp" "$(eval $bccmd)" "$(eval $prescmd)" "$(eval $pabscmd)" "$(eval $cccmd)"
            j=$(($j+1))
        done
    done
done
