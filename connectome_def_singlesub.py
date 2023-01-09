import os
import json
import bids
from itertools import product
from glob import glob
import pipetography.connectomes as pc
from sys import argv
import re

sub = [int(argv[1].strip())] #idx is [1] because [0] is the script name
ses = [str(argv[2].strip())]

def main():
	bids_folder = os.path.abspath('..')
	bids_layout = bids.layout.BIDSLayout(bids_folder)
	all_sub_list = bids_layout.get_subjects()
	ses_list = bids_layout.get_sessions()
	all_sub_ses_combos = set(product(all_sub_list, ses_list))


	skip_these = []
	for tup in all_sub_ses_combos:
		sub_ses = os.path.join(bids_folder, 'sub-'+tup[0], 'ses-'+tup[1], 'dwi')
		if not os.path.exists(sub_ses):
			skip_these.append(tup)
		elif int(tup[0])!=sub or str(tup[1])!=ses:
			skip_these.append(tup)
	
	print('Subject-Session tuples to process:')
	print(all_sub_ses_combos.difference(skip_these))


	connectomes = pc.connectome(
		BIDS_dir = '/BIDS_dir',
		skip_tuples = skip_these,
		debug=False,
		atlas_list = ['/BIDS_dir/code/Pipetography_Atlases/desikanKilliany86MNI.nii.gz','/BC_BIDS/code/Pipetography_Atlases/BN_Atlas_246_1mm.nii.gz','/BC_BIDS/code/Pipetography_Atlases/aal116MNI.nii.gz']
		)
    # connectomes.subject_template
	connectomes.create_nodes()
	connectomes.connect_nodes(wf_name='connectomes') #connectomes has to be the working folder name
	connectomes.run_pipeline(parallel=3)
    
if __name__ == '__main__':
    main()
