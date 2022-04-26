: '
bash collect-params.sh <directory with model augmentation parts from grid search>
'

outdir=$1

naugparts=$(ls -d $outdir/*/ | wc -l)

for ((i=1;i<=$naugparts;++i)); do
    if [[ $i -eq 1 ]]; then
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "part" "idx1" "idx2" "disp" "idf" "pres" "pabs"
    fi
    ma="$outdir/augs-$i"
    readarray -t paramsarr < <(find $ma -type f -name params.txt | sort -V)
    j=0
    for params in ${paramsarr[*]}; do
        IFS="="
        while read -r param values; do
            readarray -d " " $param < <(echo -n $values)
        done < $params
        k=0
        for disp in ${displacement[*]}; do
            bccmd="echo ${intensity_decay_fraction[0]}"
            prescmd="echo ${perlin_noise_res[0]}"
            pabscmd="echo ${perlin_noise_abs_max[0]}"
            printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "augs-$i" "$(($j+1))" "$(($k+1))" "$disp" "$(eval $bccmd)" "$(eval $prescmd)" "$(eval $pabscmd)"
            k=$(($k+1))
        done
        j=$(($j+1))
    done
done
