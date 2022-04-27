: '
bash rename-move-augment-files.sh <odir> <mrinames> <lesionname>
'
dir=$1
filenames=($2)
lesionname=$3
naugparts=$(ls -d $dir/*/ | wc -l)
filenames+=($lesionname)
filenames+=("interp-field")
idx=1
for ((i=1;i<=$naugparts;++i))
do
    ma="$dir/augs-$i"
    for name in ${filenames[*]}
    do
        readarray -t files < <(find $ma -type f -name $name-*.nii.gz | sort -V)
        numfiles=${#files[*]}
        #for file in ${files[*]}
        for ((j=0;j<$numfiles;++j))
        do
            file=${files[$j]}
            if [[ $name == "interp-field" ]]
            then
                cmd="mv $file $dir/$(printf %03d $(($idx+$j))).nii.gz"
            else
                cmd="mv $file $dir/$name-$(printf %03d $(($idx+$j))).nii.gz"
            fi
            #echo $cmd
            eval $cmd
        done
    done
    idx=$(($idx+$numfiles))
done

