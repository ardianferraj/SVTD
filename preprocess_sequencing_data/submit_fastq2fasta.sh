#!/bin/bash
#SBATCH --job-name=fq2fa          # Job name
#SBATCH --ntasks=1                 # Run on a single CPU
#SBATCH --cpus-per-task=1         # Number of CPU cores per task
#SBATCH --mem=32G                 # Job memory request
#SBATCH --time=24:00:00           # Time limit hrs:min:sec
#SBATCH --qos=batch
#SBATCH -o slurm.%x.%j.out        # STDOUT
#SBATCH -e slurm.%x.%j.err        # STDERR

source activate csna_env

## run this script to find the sample IDs in the files given by GT, then pipe each GT given ID into this script
## find /projects/csna/sv_ferraj/SVTD/data/sequencing/isoseq/striatum   -name "*.bam.fastq.gz" ! -name "*unbarcoded*"   | sed -E 's|.*s[0-9]+\.([0-9]{5})_GT.*|\1|'   | sort -u

python /projects/csna/sv_ferraj/SVTD/repo/preprocess_sequencing_data/fastq2fasta.py \
  ${id} \
  /projects/csna/sv_ferraj/SVTD/data/sequencing/isoseq/striatum \
  /projects/chesler-lab/csna/sv_ferraj/SVTD/data/sequencing/isoseq/striatum/merged/fastq \
  /projects/chesler-lab/csna/sv_ferraj/SVTD/data/sequencing/isoseq/striatum/merged/fasta