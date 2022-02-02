#!/bin/bash
#title           : runaf2.sh
#description     : This script submits one or more Alphafold batch jobs using a folder of proteins (.fasta or .fa files)
#author		 : Adam Camilli (a.o.camilli25@gmail.com)
#date            : 01/04/2022
#version         : 1.0    
#notes           : Configured to work only while already logged on to Tufts HPC cluster
#bash_version    : 4.2.46(2)-release (x86_64-redhat-linux-gnu)  
#==============================================================================

# Display correct usage if input is incorrect
function usage() {
  scriptName=$(basename $0);
  printf "usage: ./$scriptName [-h] [-a FILE] [-p DIR] [-o DIR] [-e DIR] FILE/DIR\n"
  printf "Run one or more Alphafold batch jobs for each protein sequence file in a directory. You can also pass in individual sequence files.\n\n"
  printf "  -h                display help\n"
  printf "  -a alphafold      optionally specify location of alphafold script \n"
  printf "                    default location: /cluster/tufts/hpc/tools/alphafold/2.1.1/alphafold/run_alphafold.py \n"
  printf "  -p alphafold path optionally specify alphafold path \n"
  printf "                    default is parent directory of provided script \n"
  printf "  -e error          optionally specify output directory \n"
  printf "                    default format: alphafold_error_<current datetime>\n"
  printf "  -o output         optionally specify error directory  (in current directory by default)\n"
  printf "                    default format: alphafold_output_<current datetime>\n"
}

# One way to pass command-line arguments to job script
# From: https://stackoverflow.com/a/36303809  
function run_sbatch () {
sbatch <<EOT
#!/bin/bash
#SBATCH -p preempt #if you don't have ccgpu access, use "preempt"
#SBATCH -n 8 # 8 cpu cores
#SBATCH --mem=64g #64GB of RAM
#SBATCH --time=2-0 #run 2 days, up to 7 days "7-00:00:00"
#SBATCH -o $1.%j
#SBATCH -e $1.%j
#SBATCH -N 1
#SBATCH --gres=gpu:1 # number of GPUs. please follow instructions in Pax User Guide
when submit jobs to different partition and selecting different GPU architectures.
module load alphafold/2.1.1
module list
nvidia-smi
module help alphafold/2.1.1 # this command will print out all input options for "runaf2"
command
source activate alphafold2.1.1
runaf2 -o $2 -f $3 -t 2024-01-01
EOT
}

numArg=$#
afScript="/cluster/tufts/hpc/tools/alphafold/2.1.1/alphafold/run_alphafold.py"
afPath=""
errorDir=""
outputDir=""
pFlag=""
eFlag=""
oFlag=""
proteinFiles=()

while getopts ha:p:e:o: flag; do
  case "${flag}" in
    h) 
       usage
       exit 0
       ;;
    a)
       afScript="$(realpath $OPTARG)"
       ;;
    p)
       pFlag=1
       afPath="$(realpath $OPTARG)"
       ;;
    e) 
       eFlag=1
       mkdir -p $OPTARG
       errorDir="$(realpath $OPTARG)"
       ;;
    o)
       oFlag=1
       mkdir -p $OPTARG
       outputDir="$(realpath $OPTARG)"
       ;;
   esac
done
shift $(($OPTIND - 1))

# Set default output and error directories
currentDateTime="$(date +%Y%m%d_%H%M%S)"
errorTitle="alphafold_error_$currentDateTime"
outputTitle="alphafold_output_$currentDateTime"

if  [[ -z $pFlag ]];
then
  afPath=$(basename $afScript)
fi
if  [[ -z $eFlag ]];
then
  mkdir $errorTitle
  errorDir="$(realpath ./$errorTitle)"
fi
if [[ -z $oFlag ]];
then
  mkdir $outputTitle
  outputDir="$(realpath ./$outputTitle)"
fi

# Run batch script for each protein sequence file 
if [[ -d $* ]]; 
then	
  shopt -s nullglob # don't match empty files
  for file in "$1"/*.{fasta,fa}; do
    proteinFiles+=("$(realpath $file)")
  done
  shopt -u nullglob
  for proteinFile in "${proteinFiles[@]}"; do
    proteinDir=$(basename $proteinFile)
    proteinErrorDir="$errorDir/${proteinDir%.*}"  
    mkdir -p $proteinErrorDir
    # run_sbatch $proteinErrorDir $afPath $afScript $outputDir $proteinFile
    run_sbatch $proteinErrorDir $outputDir $proteinFile
  done
  exit 0
elif [[ -f $* ]];
then
  proteinDir=$(basename $*)
  proteinErrorDir="$errorDir/${proteinDir%.*}"  
  mkdir -p $proteinErrorDir
  # run_sbatch $proteinErrorDir $afPath $afScript $outputDir $*
  echo "$proteinErrorDir $outputDir $*"
  run_sbatch $proteinErrorDir $outputDir $* 
  exit 0
else
  echo "Invalid or nonexistent directory $*"
  usage
  exit 1
fi
