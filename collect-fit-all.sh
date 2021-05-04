: '
bash collect-fit-all.sh <grid search input dir> <grid search output dir>
'
idir=$1
odir=$2

#idir=/home/ivar/bidsdir/derivatives/sailor-mni
#odir=/home/ivar/bidsdir/derivatives/cancer-sim-search

#readarray -t intervals_files < <(find sailor-mni -type f -name intervals_days.txt | sort)
readarray -t params_files < <(find $odir -maxdepth 2 -type f -name params-fit-*.txt | sort)

numsubs=${#params_files[*]}

printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "sub" "interv" "idays" "disp" "grange" "idf" "vecs" "angle" "splo" "sm" "pres" "pabs" "cc" "ccn"

for ((i=0; i<$numsubs; ++i))
do
    params_file=${params_files[$i]}
    IFS="="
    while read -r param value; do
        readarray -d " " $param < <(echo -n $value)
    done < $params_file

    sub=$(basename $(dirname $params_file))
    intervals_file=$idir/$sub/intervals_days.txt

    interv=$( printf '%d' $(( 10#$(echo $(basename $params_file) | grep -E -o [0-9]+) )) )
    idays=$(sed -n ${interv}p $intervals_file)

    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$sub" "$interv" "$idays" "$displacement" "$gaussian_range_one_sided" "$intensity_decay_fraction" "$num_vecs" "$angle_thr" "$spline_order" "$smoothing_std" "$perlin_noise_res" "$perlin_noise_abs_max" "$cc" "$ccnorm"
done

