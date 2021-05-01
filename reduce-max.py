import sys
import nibabel as nib
import numpy as np

img = nib.load(sys.argv[1])

nib.save(nib.Nifti1Image(np.max(img.get_fdata(), axis=-1), img.affine, img.header), sys.argv[2])
