#!/bin/bash
#SBATCH -p preempt  #if you don't have ccgpu access, use "preempt"
#SBATCH -n 8	# 8 cpu cores
#SBATCH --mem=64g	#64GB of RAM
#SBATCH --time=2-0	#run 2 days, up to 7 days "7-00:00:00"
#SBATCH -o output.%j
#SBATCH -e error.%j
#SBATCH -N 1
#SBATCH --gres=gpu:1	# number of GPUs, using v100 --gres=gpu:v100:1, using a100 --gres=gpu:a100:1

export alphafold_path=/cluster/tufts/cmdb295class/shared/alphafold/alphafold
module load cuda/11.0 cudnn/8.0.4-11.0 anaconda/2021.05
module list
nvidia-smi

source activate af2

#Make sure to specify the output_dir to a path that you have write permission

python3 /cluster/tufts/cmdb295class/shared/alphafold/alphafold/run_af2.py \
--output_dir=/cluster/home/acamilli/alphafold/output \
--fasta_paths=/cluster/home/acamilli/alphafold/sequences/7206OmpU.fa \
--max_template_date=2022-05-14
