#!/bin/bash
#SBATCH --job-name=isoSV   # Job name
#SBATCH --ntasks=1                    # Run on a single CPU
#SBATCH --cpus-per-task=1            # Number of CPU cores per task
#SBATCH --mem=2G                     # Job memory request
#SBATCH --time=48:00:00               # Time limit hrs:min:sec
#SBATCH --qos batch
#SBATCH -o slurm.%x.%j.out # STDOUT
#SBATCH -e slurm.%x.%j.err # STDERR
pwd; hostname; date
set -x

module load singularity
conda activate isoseq

nextflow run /projects/chesler-lab/csna/sv_ferraj/SVTD/repo/isoSV/isoSV.nf \
-work-dir /flashscratch/c-ferraa/isoSV/dev/work \
-resume