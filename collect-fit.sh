readarray -t files < <(find . -maxdepth 2 -type f -name params-fit-001.txt | sort)

printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "disp" "grange" "idf" "vecs" "angle" "splo" "sm" "pres" "pabs" "cc" "ccn"

for file in ${files[*]}
do
    #echo $file
    IFS="="
    while read -r param value; do
        readarray -d " " $param < <(echo -n $value)
    done < $file
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$displacement" "$gaussian_range_one_sided" "$intensity_decay_fraction" "$num_vecs" "$angle_thr" "$spline_order" "$smoothing_std" "$perlin_noise_res" "$perlin_noise_abs_max" "$cc" "$ccnorm"
done
