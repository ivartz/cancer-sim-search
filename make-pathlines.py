import sys
import nibabel as nib
import numpy as np
from dipy.io.streamline import save_tractogram
from dipy.io.stateful_tractogram import Space, StatefulTractogram
from dipy.tracking.streamline import select_random_set_of_streamlines
from dipy.io.utils import create_nifti_header, get_reference_info

mask_file = sys.argv[1]

fields_file = sys.argv[2]

res_folder = sys.argv[3]

segmentation_img = nib.load(mask_file)

affine, dimensions, voxel_sizes, voxel_order = get_reference_info(segmentation_img)

nifti_header = create_nifti_header(affine, dimensions, voxel_sizes)

segmentation_data = segmentation_img.get_fdata()

dynamic_mask = segmentation_data != 0

fields_data = nib.load(fields_file).get_fdata()

num_components = fields_data.shape[-1]

num_time_intervals = num_components // 3

pathlines_coords = np.expand_dims(np.argwhere(dynamic_mask).astype(np.float32), axis=-2)

time_surfaces = np.expand_dims(dynamic_mask.copy(), axis=-1)

for tx in range(0,num_components,3):
    d = fields_data[...,tx:tx+3][dynamic_mask]
    
    if tx > 0:
        d = np.repeat(d, counts, axis=0)
    
    dc = pathlines_coords[:,-1,:]+d
    
    pathlines_coords = np.concatenate((pathlines_coords, np.expand_dims(dc, axis=-2)), axis=-2).squeeze()
    
    dci, counts = np.unique(dc.astype(np.int32), return_counts=True, axis=0)
    
    dynamic_mask[:] = False
        
    for ind in dci:
        dynamic_mask[ind[0], ind[1], ind[2]] = True
    
    time_surfaces = np.concatenate((time_surfaces, np.expand_dims(dynamic_mask, axis=-1)), axis=-1)

nib.save(nib.Nifti1Image(time_surfaces, affine, nifti_header), res_folder+"/time-surfaces.nii.gz")

nib.save(nib.Nifti1Image(np.max(time_surfaces, axis=-1), affine, nifti_header), res_folder+"/time-surfaces-max.nii.gz")

trk = StatefulTractogram(pathlines_coords, segmentation_img, Space.VOX)

save_tractogram(trk, res_folder+"/pathlines.trk")

# https://dipy.org/documentation/1.3.0./examples_built/streamline_formats/#example-streamline-formats
trk.to_vox()

trk.to_corner()

trk_reduced_streamlines = select_random_set_of_streamlines(trk.streamlines, 512)

trk_reduced = StatefulTractogram(trk_reduced_streamlines, segmentation_img, Space.VOX)

save_tractogram(trk_reduced, res_folder+"/pathlines-reduced.trk")
