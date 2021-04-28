scriptdir=$(dirname $0)

patientsimdir=$1

realdatadir=$2

readarray -t bestsimsdirs < <(ls -d $patientsimdir/*-fit/*/*/ | sort)

fname=interp-field-*mm.nii.gz
nfname=interp-neg-field-*mm.nii.gz
wname=warped.nii.gz

dbmask=directional-binary-masks-max.nii.gz
emask=ellipsoid-mask.nii.gz
iemask=interp-ellipsoid-mask.nii.gz
igaussian=interp-gaussian.nii.gz
ioemask=interp-outer-ellipsoid-mask.nii.gz
normmask=normal-ellipsoid-mask.nii.gz
par=params.txt

t1cs=()
t2s=()
flairs=()

for scandir in $(ls -d $realdatadir/*/ | sort)
do
    t1cs+=(${scandir}T1c.nii.gz)
    t2s+=(${scandir}T2.nii.gz)
    flairs+=(${scandir}Flair.nii.gz)
done

fields=()
negfields=()
warps=()

dbmasks=()
emasks=()
iemasks=()
igaussians=()
ioemasks=()
normmasks=()
paramsfiles=()

echo "The most fit simulations are"

for bdir in ${bestsimsdirs[*]}
do
    echo $bdir
    ioemaskdir=$(dirname $bdir)
    fields+=($bdir$fname)
    negfields+=($bdir$nfname)
    warps+=($bdir$wname)
    
    dbmasks+=($ioemaskdir/$dbmask)
    emasks+=($ioemaskdir/$emask)
    iemasks+=($ioemaskdir/$iemask)
    igaussians+=($ioemaskdir/$igaussian)
    ioemasks+=($ioemaskdir/$ioemask)
    normmasks+=($ioemaskdir/$normmask)
    
    paramsfiles+=($ioemaskdir/$par)
done

echo ----

if [[ ${#fields[*]} -ne ${#warps[*]} || ${#fields[*]} -ne ${#ioemasks[*]} ]]
then
    echo "Not equal amounts of data found"
    exit
fi

echo "params"
echo ${paramsfiles[*]}

echo ----

echo "most fit fields"
echo ${fields[*]}
#echo "warps"
#echo ${warps[*]}
#echo "masks"
#echo ${ioemasks[*]}


echo ----

: '
echo "aliza ${t1cs[*]} ${warps[*]} &"

echo ----
echo "aliza ${t1cs[*]} &"
echo "aliza ${t2s[*]} &"
echo "aliza ${flairs[*]} &"

echo ----
echo "aliza ${fields[*]} &"
echo "aliza ${negfields[*]} &"
echo "aliza ${warps[*]} &"
echo ----
echo "aliza ${dbmasks[*]} &"
echo "aliza ${emasks[*]} &"
echo "aliza ${iemasks[*]} &"
echo "aliza ${igaussians[*]} &"
echo "aliza ${ioemasks[*]} &"

echo ----
echo "itksnap -g ${t1cs[0]} -o ${t1cs[*]:1:${#t1cs[*]}} &"
echo "itksnap -g ${t2s[0]} -o ${t2s[*]:1:${#t2s[*]}} &"
echo "itksnap -g ${flairs[0]} -o ${flairs[*]:1:${#flairs[*]}} &"

echo ----
echo "itksnap -g ${fields[0]} -o ${fields[*]:1:${#fields[*]}} &"
echo "itksnap -g ${negfields[0]} -o ${negfields[*]:1:${#negfields[*]}} &"


echo "itksnap -g ${warps[0]} -o ${warps[*]:1:${#warps[*]}} &"
echo ----
echo "itksnap -g ${dbmasks[0]} -o ${dbmasks[*]:1:${#dbmasks[*]}} &"
echo "itksnap -g ${emasks[0]} -o ${emasks[*]:1:${#emasks[*]}} &"
echo "itksnap -g ${iemasks[0]} -o ${iemasks[*]:1:${#iemasks[*]}} &"
echo "itksnap -g ${igaussians[0]} -o ${igaussians[*]:1:${#igaussians[*]}} &"
echo "itksnap -g ${ioemasks[0]} -o ${ioemasks[*]:1:${#ioemasks[*]}} &"

echo ----
'

# Merge results
#: '
cmd="fslmerge -t $patientsimdir/dbmask.nii.gz ${dbmasks[*]}"
echo $cmd
eval $cmd
cmd="fslmerge -t $patientsimdir/emask.nii.gz ${emasks[*]}"
echo $cmd
eval $cmd
cmd="fslmerge -t $patientsimdir/iemask.nii.gz ${iemasks[*]}"
echo $cmd
eval $cmd
cmd="fslmerge -t $patientsimdir/igaussian.nii.gz ${igaussians[*]}"
echo $cmd
eval $cmd
cmd="fslmerge -t $patientsimdir/ioemask.nii.gz ${ioemasks[*]}"
echo $cmd
eval $cmd
cmd="fslmerge -t $patientsimdir/normmask.nii.gz ${normmasks[*]}"
echo $cmd
eval $cmd
cmd="fslmaths $patientsimdir/dbmask.nii.gz -add $patientsimdir/emask.nii.gz $patientsimdir/sim.nii.gz"
echo $cmd
eval $cmd
cmd="fslmaths $patientsimdir/sim.nii.gz -add $patientsimdir/iemask.nii.gz $patientsimdir/sim.nii.gz"
echo $cmd
eval $cmd
#cmd="fslmerge -t $patientsimdir/true.nii.gz ${t1cs[*]:1:${#t1cs[*]}}"
cmd="fslmerge -t $patientsimdir/true.nii.gz ${t1cs[*]}"
echo $cmd
eval $cmd
cmd="fslmerge -t $patientsimdir/synth.nii.gz ${warps[*]}"
echo $cmd
eval $cmd
cmd="fslmerge -t $patientsimdir/fields.nii.gz ${fields[*]}"
echo $cmd
eval $cmd
cmd="fslmerge -t $patientsimdir/negfields.nii.gz ${negfields[*]}"
echo $cmd
eval $cmd
echo ----
#echo "itksnap -g $patientsimdir/true.nii.gz -o $patientsimdir/synth.nii.gz $patientsimdir/sim.nii.gz $patientsimdir/normmask.nii.gz"
echo "itksnap -g true.nii.gz -o synth.nii.gz sim.nii.gz normmask.nii.gz negfields.nii.gz" > $patientsimdir/open.sh
echo "itksnap -g true.nii.gz -o synth.nii.gz sim.nii.gz normmask.nii.gz negfields.nii.gz"
#'
