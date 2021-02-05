#dataset="/mnt/HDD3TB/derivatives/cancer-sim-search-SAILOR_PROCESSED_MNI-001-QUUyOkRb-longitudinal"

export LC_NUMERIC="en_US.UTF-8" 

dataset=$1

scriptdir=$(dirname $0)

c=1

for f in $(find $dataset -type f -name results-cc.txt | sort)
do
    #echo "python3 $scriptdir/highest-mag-thr.py $f"
    readarray -t a < <(python3 $scriptdir/highest-mag-thr.py $f)
    num=${#a[@]}
    for ((i=0; i<$((num-1)); ++i))
    do
        item=${a[i]}
        b=($item)
        eval ${b[0]}=${b[1]}
    done
    fpo=$(dirname $f)
    fp="$fpo/models-${part%.*}"
    readarray -t sims < <(ls $fp/*/*/warped.nii.gz | sort)
    id=${idx%.*}
    fp="$(dirname ${sims[$((id-1))]})"
    echo $fp

    # Reconstruct and store params file
    fpo=$(dirname $fp)
    
    while read -r line; do
        readarray -t -d "=" item <<< $line
        param=${item[0]}
        value=${item[1]}
        if [[ $param == "gaussian_range_one_sided" || $param == "num_vecs" || $param == "angle_thr" || $param == "spline_order" || $param == "smoothing_std" ]]
        then
            eval $param=$value
        fi
    done < $fpo/params.txt

    oparams=$dataset/params-fit-$(printf %03d $c).txt
    
    c=$((c+1))
    
    echo "displacement=$(printf %.2f $disp)" > $oparams
    echo "gaussian_range_one_sided=${gaussian_range_one_sided[0]}" >> $oparams
    echo "intensity_decay_fraction=$(printf %.2f $idf)" >> $oparams
    echo "num_vecs=${num_vecs[0]}" >> $oparams
    echo "angle_thr=${angle_thr[0]}" >> $oparams
    echo "spline_order=${spline_order[0]}" >> $oparams
    echo "smoothing_std=${smoothing_std[0]}" >> $oparams
    echo "perlin_noise_res=$(printf %.2f $pres)" >> $oparams
    echo "perlin_noise_abs_max=$(printf %.2f $pabs)" >> $oparams
    echo "cc=$cc" >> $oparams
    echo "ccnorm=$ccnorm" >> $oparams
done
