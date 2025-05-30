#!/usr/bin/env python3
"""
merge_and_convert_one.py

Description:
-------------
For a given sample ID, this script:
1. Recursively searches a parent directory for all `.bam.fastq.gz` files matching that sample.
2. Merges them into one gzipped FASTQ file named `<sample_id>.merged.bam.fastq.gz`.
3. Converts that file into gzipped FASTA format as `<sample_id>.merged.fa.gz`.

Usage:
-------------
python merge_and_convert_one.py <sample_id> <input_parent_dir> <output_fastq_dir> <output_fasta_dir>

Example:
-------------
python merge_and_convert_one.py \
  55555 \
  /projects/csna/sv_ferraj/SVTD/data/sequencing/isoseq/striatum \
  /projects/chesler-lab/csna/sv_ferraj/SVTD/data/sequencing/isoseq/striatum/merged/fastq \
  /projects/chesler-lab/csna/sv_ferraj/SVTD/data/sequencing/isoseq/striatum/merged/fasta
"""

import gzip
import shutil
import sys
from pathlib import Path

def merge_fastqs(fq_paths, merged_fastq_path):
    with gzip.open(merged_fastq_path, "wb") as out_f:
        for fq in fq_paths:
            with gzip.open(fq, "rb") as in_f:
                shutil.copyfileobj(in_f, out_f)

def convert_to_fasta(fastq_path, fasta_path):
    with gzip.open(fastq_path, "rt") as fq_in, gzip.open(fasta_path, "wt") as fa_out:
        while True:
            header = fq_in.readline()
            seq = fq_in.readline()
            plus = fq_in.readline()
            qual = fq_in.readline()
            if not qual:
                break  # EOF
            if not (header and seq and plus and qual):
                continue
            fa_out.write(f">{header[1:].strip()}\n{seq.strip()}\n")

def main():
    if len(sys.argv) != 5:
        print("Usage: python merge_and_convert_one.py <sample_id> <input_parent_dir> <output_fastq_dir> <output_fasta_dir>")
        sys.exit(1)

    sample_id = sys.argv[1]
    parent_dir = Path(sys.argv[2])
    output_fastq_dir = Path(sys.argv[3])
    output_fasta_dir = Path(sys.argv[4])

    output_fastq_dir.mkdir(parents=True, exist_ok=True)
    output_fasta_dir.mkdir(parents=True, exist_ok=True)

    fq_files = list(parent_dir.rglob(f"*.{sample_id}_*.bam.fastq.gz"))
    fq_files = [f for f in fq_files if "unbarcoded" not in f.name]

    if not fq_files:
        print(f"No FASTQ files found for sample ID {sample_id}")
        sys.exit(1)

    merged_fastq_path = output_fastq_dir / f"{sample_id}.merged.bam.fastq.gz"
    fasta_output_path = output_fasta_dir / f"{sample_id}.merged.fa.gz"

    print(f"Merging {len(fq_files)} FASTQ files for sample {sample_id}...")
    merge_fastqs(fq_files, merged_fastq_path)
    print(f"✓ Merged FASTQ written to {merged_fastq_path}")

    print(f"Converting merged FASTQ to FASTA...")
    convert_to_fasta(merged_fastq_path, fasta_output_path)
    print(f"✓ FASTA written to {fasta_output_path}")

if __name__ == "__main__":
    main()
