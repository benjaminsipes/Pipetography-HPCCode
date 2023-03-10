#!/bin/bash

# # Wynton Submissions:
#$ -S /bin/bash
#$ -N PP_Preproc
#$ -cwd
#$ -j y
#$ -l mem_free=40G
#$ -l h_rt=12:00:00 #note: time limit is 7-days
#$ -o /wynton/protected/home/rad-brain/bsipes/outlog_general

# # Radiology SCS Submissions:
# #SBATCH --job-name=PP_Preproc
# #SBATCH --nodes=1
# #SBATCH --ntasks=1
# #SBATCH --cpus-per-task=10
# #SBATCH --mem=40G
# #SBATCH --time=12:00:00 #note: time limit is 2-days
# #SBATCH --output=/home/%u/slurm/%x-%j.log

/bin/echo Running on host: `hostname`.
/bin/echo In directory: `pwd`
/bin/echo Starting on: `date`


bids_root_dir=`pwd`/..

# # From Wynton:
pipetography_path=/protected/data/rajlab1/shared_data/singularity/images/pipetography_latest.sif
# # From Radiology SCS:
# pipetography_path=/data/i2/software/singularity/pipetography_latest.sif

# Singularity container call:
echo "Initiating singularity pipetography preprocesing job for sub-${1} ses-${2}..."

singularity exec -e -B $bids_root_dir:/BIDS_dir --pwd $PWD $pipetography_path python /BIDS_dir/code/preprocess_def_singlesub.py $1 $2

date
echo "Preprocessing Job script for sub-${1} ses-${2} complete."
#Approximate Run Time per subject = 1-2 hours

# # Job Summary Wynton:
qstat -j $JOB_ID

# # Job Summary Radiology SCS:
# squeue -j $SLURM_JOB_ID -o "%.18i %.9P %.8j %.8c %.8u %.8T %.10M %.9l %.6D %R %D"
