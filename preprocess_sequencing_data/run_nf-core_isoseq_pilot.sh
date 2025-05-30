#!/bin/bash
#SBATCH --job-name=nf-isoseq          # Job name
#SBATCH --ntasks=1                 # Run on a single CPU
#SBATCH --cpus-per-task=1         # Number of CPU cores per task
#SBATCH --mem=12G                 # Job memory request
#SBATCH --time=72:00:00           # Time limit hrs:min:sec
#SBATCH --qos=batch
#SBATCH -o slurm.%x.%j.out        # STDOUT
#SBATCH -e slurm.%x.%j.err        # STDERR

pwd; hostname; date
set -x

# Load modules
source activate csna_env
module load singularity

# Run nf-core/isoseq from HiFi reads 
nextflow run /projects/csna/sv_ferraj/SVTD/nf-core_isoseq \
  --input /projects/csna/sv_ferraj/SVTD/assets/phase1_samplesheet_test.csv \
  --fasta /projects/chesler-lab/csna/sv_ferraj/SVTD/data/ref/mm39.fa \
  --gtf /projects/chesler-lab/csna/sv_ferraj/SVTD/data/ref/gencode.vM36.annotation.gtf \
  --entrypoint map \
  --primers /projects/chesler-lab/csna/sv_ferraj/SVTD/assets/isoseq_primers.fa \
  --aligner minimap2 \
  --outdir /flashscratch/c-ferraa/isoseq/out \
  -work-dir /flashscratch/c-ferraa/isoseq/work \
  -profile slurm \
  -resume