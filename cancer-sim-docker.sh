: '
Note!
$USER should be able to run the "docker" command without sudo
https://docs.docker.com/engine/install/linux-postinstall/
'
docker run --rm repronim/neurodocker:0.7.0 generate docker \
	--base debian:stretch \
	--pkg-manager=apt \
	--ants version=2.3.1 \
	--dcm2niix version=master method=source \
	--convert3d version=1.0.0 \
	--fsl version=6.0.3 \
	--install less htop vim tmux rsync nload git openssh-client \
	--run "groupadd -g $(id -g $USER) $(id -g $USER) && useradd -u $(id -u $USER) -g $(id -g $USER) --create-home --shell /bin/bash $USER" \
	--user $USER \
	--miniconda \
		create_env="cancer-sim" \
		activate=true \
		conda_install="python=3.9 numpy nibabel scipy pandas psutil dvc dipy" \
		pip_install="git+https://github.com/pvigier/perlin-numpy" \
	--workdir "/home/$USER" \
    --run "echo 'git clone https://github.com/CRAI-OUS/bidsdir' > ~/download-code.sh" \
	--run "echo 'git clone https://github.com/ivartz/cancer-sim bidsdir/code/cancer-sim' >> ~/download-code.sh" \
	--run "echo 'git clone https://github.com/ivartz/cancer-sim-search bidsdir/code/cancer-sim-search' >> ~/download-code.sh" \
	--run "echo 'git clone https://github.com/ivartz/cancer-sim-viz bidsdir/code/cancer-sim-viz' >> ~/download-code.sh" \
	--env "bidsdir=/home/$USER/bidsdir" \
	--env "cancersimdir=/home/$USER/bidsdir/code/cancer-sim" \
	--env "cancersimsearchdir=/home/$USER/bidsdir/code/cancer-sim-search" \
	--env "cancersimvizdir=/home/$USER/bidsdir/code/cancer-sim-viz" \
    --run "echo 'set -g default-command /bin/bash\nset -g default-terminal "screen-256color"' > ~/.tmux.conf" \
    --run "echo 'syntax on\nset tabstop=4\nset softtabstop=4\nset shiftwidth=4\nset expandtab\nset autoindent\nset background=dark' > ~/.vimrc" \
	--cmd bash > Dockerfile

: '
docker build --network=host --tag=cancer-sim .

docker run -it --net=host -v $(pwd)/bidsdir:/home/$USER cancer-sim
'
docker build --tag=cancer-sim .

echo "Start from here:"

echo "mkdir -p bidsdir-mount"

echo "docker run -it -v $(pwd)/bidsdir-mount:/home/$USER/bidsdir --expose 8000 cancer-sim"

echo "tmux"

echo "cd $cancersimvizdir && python3 -m http.server"
