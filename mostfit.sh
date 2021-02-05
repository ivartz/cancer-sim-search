scriptdir=$(dirname $0)

patientsimdir=$1

readarray -t bestsimsdirs < <(bash $scriptdir/mostfit-sims.sh $patientsimdir)

fname=interp-field-*mm.nii.gz
wname=warped.nii.gz
ioemask=interp-outer-ellipsoid-mask.nii.gz
par=params.txt

bfields=()
bwarps=()
bioemasks=()
paramsfiles=()

#echo "The best fitted simulations are"

for bdir in ${bestsimsdirs[*]}
do
    #echo $bdir
    bioemaskdir=$(dirname $bdir)
    bfields+=($bdir/$fname)
    bwarps+=($bdir/$wname)
    bioemasks+=($bioemaskdir/$ioemask)
    paramsfiles+=($bioemaskdir/$par)
done

echo ----

if [[ ${#bfields[*]} -ne ${#bwarps[*]} || ${#bfields[*]} -ne ${#bioemasks[*]} ]]
then
    echo "Not equal amounts of data found"
    exit
fi

: '
echo "params"
echo ${paramsfiles[*]}

echo ----

echo "best fit fields"
echo ${bfields[*]}
#echo "warps"
#echo ${bwarps[*]}
#echo "masks"
#echo ${bioemasks[*]}

echo ----
echo "aliza ${bfields[*]} &"
echo "aliza ${bwarps[*]} &"
echo "aliza ${bioemasks[*]} &"

echo ----
echo "itksnap -g ${bfields[0]} -o ${bfields[*]:1:${#bfields[*]}} &"
echo "itksnap -g ${bwarps[0]} -o ${bwarps[*]:1:${#bwarps[*]}} &"
echo "itksnap -g ${bioemasks[0]} -o ${bioemasks[*]:1:${#bioemasks[*]}} &"
'
