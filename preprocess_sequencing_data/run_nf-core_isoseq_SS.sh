#!/bin/bash
#SBATCH --job-name=ss_nf-isoseq          # Job name
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
conda activate csna_env
module load singularity

# sample names should be in the format of "strain-sex-tissue" (e.g. "B6-F-striatum")

# make sample out and work directories if they dont exist
outdir=/flashscratch/c-ferraa/isoseq/ss/nf_ss_outputs/${sample}
workdir=/flashscratch/c-ferraa/isoseq/ss/nf_ss_workdirs/${sample}
mkdir -p ${outdir}
mkdir -p ${workdir}

# designate sample sheet for sample specific run
samplesheet=/projects/csna/sv_ferraj/SVTD/assets/${sample}_samplesheet.csv

# Extract strain from sample name
strain=$(echo "$sample" | cut -d'-' -f1)

# get strain assembly
sample_assembly="/projects/chesler-lab/csna/sv_ferraj/SVTD/data/ferraj_et_al/genome_assemblies/${strain}_flye_gcpp.fa.gz"

# liftoff gtf
liftoff_gtf="/projects/chesler-lab/csna/sv_ferraj/SVTD/analysis/liftoff/${strain}/${strain}_liftoff_mapped.gtf"

# file checks
if [[ ! -f "$samplesheet" ]]; then
  echo "❌ Error: Samplesheet not found: $samplesheet"
  exit 1
fi

if [[ ! -f "$sample_assembly" ]]; then
  echo "❌ Error: Genome assembly not found: $sample_assembly"
  exit 1
fi

if [[ ! -f "$liftoff_gtf" ]]; then
  echo "❌ Error: Liftoff GTF not found: $liftoff_gtf"
  exit 1
fi

# Run nf-core/isoseq from HiFi reads 
nextflow run /projects/csna/sv_ferraj/SVTD/nf-core_isoseq \
  --input ${samplesheet} \
  --fasta ${sample_assembly} \
  --gtf ${liftoff_gtf} \
  --entrypoint map \
  --primers /projects/chesler-lab/csna/sv_ferraj/SVTD/assets/isoseq_primers.fa \
  --aligner minimap2 \
  --outdir ${outdir} \
  -work-dir ${workdir} \
  -profile slurm \
  -resume