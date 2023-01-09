import os
import json
import bids
from itertools import product
from glob import glob
import pipetography.pipeline as pp
from sys import argv
import re

sub = [int(argv[1].strip())] #idx is [1] because [0] is the script name
ses = [str(argv[2].strip())]

def main():
	bids_folder = os.path.abspath('..')
	bids_layout = bids.layout.BIDSLayout(bids_folder)
	sub_list = bids_layout.get_subjects()
	ses_list = bids_layout.get_sessions()
	all_sub_ses_combos = set(product(sub_list, ses_list))

	skip_these = []
	for tup in all_sub_ses_combos:
		sub_ses = os.path.join(bids_folder, 'sub-'+tup[0], 'ses-'+tup[1], 'dwi')
		if not os.path.exists(sub_ses):
			skip_these.append(tup)
		elif int(tup[0])!=sub or str(tup[1])!=ses:
			skip_these.append(tup)

	
	print('Subject-Session tuples to process:')
	print(all_sub_ses_combos.difference(skip_these))

	#starting pipeline
	dwi_preproc = pp.pipeline(
		BIDS_dir='/BIDS_dir',
		ext='nii.gz',
		rpe_design='-rpe_none',
		regrid=True,
		gmwmi=False,
		mrtrix_nthreads=8,
		skip_tuples=skip_these,
		debug=False)
	dwi_preproc.create_nodes()
	dwi_preproc.connect_nodes(rpe_design='-rpe_none')
	dwi_preproc.workflow.base_dir = '/BIDS_dir/code/workingdir'
	dwi_preproc.run_pipeline(parallel=2)

if __name__ == '__main__':
	main()
