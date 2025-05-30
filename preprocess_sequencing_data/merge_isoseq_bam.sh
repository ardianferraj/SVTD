#!/bin/bash
#SBATCH --job-name=merge_bam          # Job name
#SBATCH --ntasks=1                 # Run on a single CPU
#SBATCH --cpus-per-task=1         # Number of CPU cores per task
#SBATCH --mem=32G                 # Job memory request
#SBATCH --time=24:00:00           # Time limit hrs:min:sec
#SBATCH --qos=batch
#SBATCH -o slurm.%x.%j.out        # STDOUT
#SBATCH -e slurm.%x.%j.err        # STDERR

###############################################################################
# Script: merge_bams_for_gtid.sh
#
# Description:
#   This script merges PacBio HiFi BAM files for a *single* GT ID using pbmerge.
#   It uses a TSV mapping file to translate the GT ID into the biological sample name.
#
# Usage:
#   sbatch --export=ALL,gt_it=<gt_id> merge_isoseq_bam.sh
#
# Example:
#  sbatch --export=ALL,gt_it=55555 merge_isoseq_bam.sh
#
# Output:
#   - ${sample_name}.hifi.merged.bam written to:
#     /projects/csna/sv_ferraj/SVTD/data/sequencing/isoseq/striatum/merged/bam
#
# Requirements:
#   - pbmerge must be available in the PATH
#
# Author: Ardian Ferraj
# Date: 2025-05-08
###############################################################################

# --- Constants ---
tsv="/projects/csna/sv_ferraj/SVTD/data/sequencing/isoseq/striatum/gt_sample_key.tsv"
outdir="/projects/csna/sv_ferraj/SVTD/data/sequencing/isoseq/striatum/merged/bam"
mkdir -p "$outdir"

# --- Get sample name ---
sample_name=$(awk -v id="$gt_id" '$1 == id { print $2 }' "$tsv")
if [[ -z "$sample_name" ]]; then
  echo "❌ No sample name found for gt_id $gt_id in $tsv"
  exit 1
fi

tissue=$(echo "$sample_name" | cut -d '_' -f 3)

# --- Find BAM files ---
gt_run_dirs="/projects/chesler-lab/csna/sv_ferraj/SVTD/data/sequencing/isoseq/${tissue}/raw"

bam_files=$(find "$gt_run_dirs" -type f -name "*${gt_id}*.bam" \
  ! -name "*.fail_*" ! -name "*.unassigned*" ! -name "*.non_passing*" | sort)

if [[ -z "$bam_files" ]]; then
  echo "⚠️  No BAM files found for gt_id $gt_id ($sample_name)"
  exit 2
fi

# --- Merge ---
echo "🔄 Merging ${gt_id} → ${sample_name} ..."
pbmerge -o "${outdir}/${sample_name}.hifi.merged.bam" -j 32 $bam_files
echo "✅ Merged BAM saved to ${outdir}/${sample_name}.hifi.merged.bam"
