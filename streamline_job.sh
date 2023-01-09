#!/bin/bash

# # Wynton Submissions:
#$ -S /bin/bash
#$ -N PP_Streams
#$ -cwd
#$ -q gpu.q
#$ -j y
#$ -l mem_free=64G
#$ -l h_rt=1:00:00 #gross overestimate, probably closer to 5-10min
#$ -o /wynton/protected/home/rad-brain/bsipes/outlog_general

# # Radiology SCS Submissions:
# #SBATCH --job-name=PP_Streams
# #SBATCH --nodes=1
# #SBATCH --ntasks=1
# #SBATCH --nodelist=cronus #I've had best luck with cronus, although other nodes may work fine, too.
# #SBATCH -N 1 --partition=gpu --ntasks-per-node=1
# #SBATCH --gres=gpu:1
# #SBATCH --mem=64G
# #SBATCH --time=1:00:00 #gross overestimate, probably closer to 5-10min
# #SBATCH --output=/home/%u/slurm/%x-%j.log

# Run NVIDIA GPU Streamline generation:
# You will need to request GPU resources on UCSF radiology, for GPU resources with an interactive shell: qrsh -l gpu=# -q rad_gpu.q@host.radiology.ucsf.edu
# Check which GPUs are assigned to you after getting into the qrsh session with `echo $CUDA_VISIBLE_DEVICES`

echo "Running Tractography for sub-${1} ses-${2}"

# Default parameters for the streamline generation code:
NGPUS=1 # number of GPUS (same as what you requested)
MIN_SIGNAL=1.0e-5
CHUNK_SIZE=90000 # GPU paralleled file writing size
ANGLE_DEG=60 # search angle
MAX_ANGLE=1.04719753 # ANGLE_DEG*pi/180
THRESHOLD=0.1
STEP_SIZE=0.5
SEED_DENS=1

bids_root_dir=`pwd`/..

# # From Wynton:
gpustreamlines_path=/protected/data/rajlab1/shared_data/singularity/images/gpustreamlines.sif
# # From Radiology SCS:
# gpustreamlines_path=/data/rajlab1/shared_data/singularity/images/gpustreamlines.sif


#Make Directories for Outputs
mkdir $bids_root_dir/derivatives/pipetography/sub-$1/ses-$2/tracktography
mkdir -p $bids_root_dir/derivatives/streamlines/sub-$1/ses-$2

# Inputs:
#     - BVEC={PATH TO}.bvec
#       BVAL={PATH TO}.bval
#       DTI={PATH TO}.nii.gz
#       MASK=Streamline possible locations mask - whole brain mask
#       ROI=Seed start mask - grey matter white matter interface
BVEC='/input/dwi_space-acpc_res-1mm.bvecs'
BVAL='/input/dwi_space-acpc_res-1mm.bvals'
DTI='/input/dwi_space-acpc_res-1mm.nii.gz'
MASK='/input/dwi_space-acpc_res-1mm_seg-brain_mask.nii.gz'
#ROI='/input/T1w_space-acpc_seg-gmwmi_mask.nii.gz' #Removed for whole-brain seeding
PREFIX='/opt/exec/output/tmp-sub01'  # prefix to name temporary chunk files
TMPFILES='tmp-sub01*' # temp output file with wild card ex: tmp-*

# 2. Execute singularity container:
singularity exec --nv -B $bids_root_dir/derivatives/pipetography/sub-$1/ses-$2/tracktography:/opt/exec/output -B $bids_root_dir/derivatives/pipetography/sub-$1/ses-$2/preprocessed:/input $gpustreamlines_path python /opt/exec/run_dipy_gpu.py $DTI $BVAL $BVEC $MASK --roi_nifti $MASK --chunk-size $CHUNK_SIZE --output-prefix $PREFIX --ngpus $NGPUS --use-fast-write --max-angle $MAX_ANGLE --min-signal $MIN_SIGNAL --tc-threshold $THRESHOLD --step-size $STEP_SIZE --sampling-density $SEED_DENS

echo "Merging track chunks..."
# 3. Merge chunks back together to 1 trk file
singularity exec --nv --pwd /opt/exec/output -B $bids_root_dir/derivatives/pipetography/sub-$1/ses-$2/tracktography:/opt/exec/output $gpustreamlines_path /opt/exec/merge_trk.sh $TMPFILES -o "sub-$1_ses-$2_gmwmi2wm.trk" 

echo "Deleting track chuncks..."
# 5. Delete all tmp chunks 
cd $bids_root_dir/derivatives/pipetography/sub-$1/ses-$2/tracktography 
rm $TMPFILES

echo "Converting TRK file to TCK..."
# 6. Convert trk to tck for mrtrix3 compatibility
# From Wynton:
$bids_root_dir/code/trk2tck -i $bids_root_dir/derivatives/pipetography/sub-$1/ses-$2/tracktography/"sub-$1_ses-$2_gmwmi2wm.trk" -o $bids_root_dir/derivatives/pipetography/sub-$1/ses-$2/tracktography/"sub-$1_ses-$2_gmwmi2wm.tck" -c 3

mv $bids_root_dir/derivatives/pipetography/sub-$1/ses-$2/tracktography/"sub-$1_ses-$2_gmwmi2wm.tck" $bids_root_dir/derivatives/streamlines/sub-$1/ses-$2
rm -r $bids_root_dir/derivatives/pipetography/sub-$1/ses-$2/tracktography

echo "Streamline generation script for sub-${1} ses-${2} complete."

# # Job Summary Wynton:
qstat -j $JOB_ID

# # Job Summary Radiology SCS:
# squeue -j $SLURM_JOB_ID -o "%.18i %.9P %.8j %.8c %.8u %.8T %.10M %.9l %.6D %R %D"