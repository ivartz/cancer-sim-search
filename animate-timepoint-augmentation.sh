: '
bash animate-timepoint-augmentation.sh <folder with augmentations> <mriname> <lesionname>

F.ex.
bash animate-timepoint-augmentation.sh /mnt/HDD18TB/ivar/bidsdir-mount/derivatives/lidia-aug/sub-02/ses-01 flair seg
'
dir=$1
mriname=$2
lesionname=$3
odir=$dir/$mriname-anim
mkdir -p $odir
codedir=/mnt/HDD18TB/ivar/bidsdir-mount/code
#codedir=/run/user/1000/gvfs/smb-share:server=10.54.218.156,share=hdd18tb-ivar/bidsdir-mount/code
cd $codedir
# activate anaconda virtual env with fsleyes installed
bash animate-two-niftis.sh $(find $dir -type f -name $mriname-* | sort -V) $(find $dir -type f -name $lesionname-* | sort -V) $odir
