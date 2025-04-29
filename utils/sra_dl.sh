#!/bin/bash
#SBATCH --job-name=dl_data   # Job name
#SBATCH --ntasks=1                    # Run on a single CPU
#SBATCH --cpus-per-task=1            # Number of CPU cores per task
#SBATCH --mem=16G                     # Job memory request
#SBATCH --time=24:00:00               # Time limit hrs:min:sec
#SBATCH --qos batch
#SBATCH -o slurm.%x.%j.out # STDOUT
#SBATCH -e slurm.%x.%j.err # STDERR
pwd; hostname; date
set -x

source activate csna_env

echo Download Directory: ${dl_dir}
echo SRA ID: ${id}

cd ${dl_dir}

fasterq-dump  ${id}
# fastq-dump --split-files ${id}