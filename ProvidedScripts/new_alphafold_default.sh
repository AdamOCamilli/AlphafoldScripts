#!/bin/bash
#SBATCH -p ccgpu #if you don't have ccgpu access, use "preempt"
#SBATCH -n 8 # 8 cpu cores
#SBATCH --mem=64g #64GB of RAM
#SBATCH --time=2-0 #run 2 days, up to 7 days "7-00:00:00"
#SBATCH -o output.%j
#SBATCH -e error.%j
#SBATCH -N 1
#SBATCH --gres=gpu:1 # number of GPUs, using v100 --gres=gpu:v100:1, using a100 --
gres=gpu:a100:1
export alphafold_path=/cluster/tufts/hpc/tools/alphafold/2.1.1/alphafold
module load cuda/11.0 cudnn/8.0.4-11.0 anaconda/2021.05
module list
nvidia-smi
source activate alphafold2.1.1
python3 /cluster/tufts/hpc/tools/alphafold/2.1.1/alphafold/run_alphafold.py --
data_dir=/cluster/tufts/hpc/tools/alphafold/2.1.1/db --
output_dir=/cluster/tufts/hpc/tools/alphafold/2.1.1/test --
fasta_paths=/cluster/tufts/cmdb295class/shared/alphafold/alphafold/T1050.fasta --
max_template_date=2020-05-14
