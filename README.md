# cancer-sim-search
Robust monitoring cancer and treatment related displacements in the brain on longitudinal MRI scans. An interactive visualization of example results is available [here](https://cancer-sim.com/)

## [BIDS](https://bids.neuroimaging.io/)-like directory structure
```
bidsdir-mount
├── code
│   └── github-clones-here.txt
└── derivatives
    ├── cancer-sim-search
    ├── output-from-various-pipelines.txt
    └── example-processed-dataset-as-input
        ├── all-mri-coregistrated-for-each-patient.txt
        └── sub-01
            ├── ses-01
            │   ├── BrainExtractionMask.nii.gz
            │   ├── T1c.nii.gz
            │   └── TumorMask.nii.gz
            └── ses-02
                └── T1c.nii.gz
```

## Data augmentations for each time point examination
1. Generate Dockerfile, build and run container by following instructions given from `bash cancer-sim-docker.sh`
2. Download BIDS-like dataset to derivatives subdirectory
3. Customize search parameters within `grid-search-2d.sh` or `grid-search-3d.sh`
4. Customize output directory etc. in run.sh, then `bash run.sh`

## How to fit the model to each time point examination interval
1. Generate Dockerfile, build and run container by following instructions given from `bash cancer-sim-docker.sh`
2. Download longitudially coregistered BIDS-like dataset to derivatives subdirectory
3. Customize search parameters within `grid-search-2d.sh` or `grid-search-3d.sh`
4. Customize output directory etc. in run.sh, then `bash run.sh`

## Analyzing results from longitudinal assessment of model fit
A successful grid search between two MRI examinations for a patient, returns a cross-correlation measure for each model projection in a text file in the output directory specified in `run.sh` for the given patient sub-folder,  as shown below. The best fit model is automatically selected from this list according to a threshold and heuristic specified in `highest-mag-thr.py`
```bash
timestep   part    idx disp    idf pres    pabs    cc
ses-01_ses-02   1   1   -3.00   0.20    0.03    0   0.5593861725
ses-01_ses-02   2   1   -1.00   0.20    0.03    0   0.6699303193
ses-01_ses-02   3   1   1.00    0.20    0.03    0   0.7132757302
ses-01_ses-02   4   1   3.00    0.20    0.03    0   0.6577610362
ses-01_ses-02   5   1   -3.00   0.55    0.03    0   0.3156328553
ses-01_ses-02   6   1   -1.00   0.55    0.03    0   0.4358467782
ses-01_ses-02   7   1   1.00    0.55    0.03    0   0.5204704870
ses-01_ses-02   8   1   3.00    0.55    0.03    0   0.4942922409
ses-01_ses-02   9   1   -3.00   0.90    0.03    0   0.2911394319
ses-01_ses-02   10  1   -1.00   0.90    0.03    0   0.4445073207
ses-01_ses-02   11  1   1.00    0.90    0.03    0   0.5477226115
ses-01_ses-02   12  1   3.00    0.90    0.03    0   0.5338348719
```
## Search parameters
2D or 3D parameter search as specified with `ndims` in `run.sh`
- 2D: Maximum tissue displacement and tumor infiltration, `grid-search-2d.sh`

        1. Maximum tissue displacement (disp) [mm] ∈ [min, max] where max > min and both can have positive or negative  sign.
		2. Tumor infiltration, or specifically "intensity decay fraction" (idf) ∈ <0, 1], with 1 least infiltration and highest intensity decay away from the geometric center of the tumor in a radial direction.

- 3D: Maximum tissue displacement, tumor infiltration and growth irregularity, `grid-search-3d.sh`

		3. Growth irregularity, or Perlin noise resolution (pres) ∈ <0, 1], 1 least granularity and lowest resolution. Additive Perlin noise on displacement field.
		
## System requirements
Tuned to use half of the available CPU threads and with a RAM/CPU ratio of 1.5. This means that it requires at least 1.5 GB available system memory per CPU thread for half of the available CPU threads in the system. Examples with RAM/CPU=1.5:
- 24 GB RAM / 16 CPU threads
- 96 GB RAM / 64 CPU threads
