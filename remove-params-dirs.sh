: '
bash remove-params-dirs.sh <session folder with data augmentations>
'

dir=$1

find $dir -type f -name params.txt -exec bash -c 'cmd="rm $0"; eval $cmd' {} \;
find $dir -mindepth 1 -maxdepth 1 -type d -exec bash -c 'cmd="rm -rd $0"; eval $cmd' {} \;

