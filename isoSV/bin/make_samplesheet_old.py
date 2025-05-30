#!/usr/bin/env python3

import csv
import os
import argparse

def find_bam_files(root_dir, pattern=".hifi.merged.bam"):
    bam_files = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith(pattern):
                bam_files.append(os.path.join(dirpath, filename))
    return bam_files

def main():
    parser = argparse.ArgumentParser(description="Generate Iso-Seq samplesheet from hifi.merged.bam files.")
    parser.add_argument("-d", "--directory", required=True, help="Root directory to search for *.hifi.merged.bam files")
    parser.add_argument("-o", "--output", required=True, help="Output CSV file path")
    parser.add_argument("--reference", default="/projects/chesler-lab/csna/sv_ferraj/SVTD/data/ref/mm39/mm39.fa", help="Reference genome FASTA")
    parser.add_argument("--gtf", default="/projects/chesler-lab/csna/sv_ferraj/SVTD/data/ref/mm39/gencode.vM36.annotation.gtf", help="Reference annotation GTF")
    args = parser.parse_args()

    bam_files = find_bam_files(args.directory)
    if not bam_files:
        print("No .hifi.merged.bam files found.")
        return

    with open(args.output, mode='w', newline='') as csvfile:
        fieldnames = ["sampleID", "flnc_bam", "reference", "reference_gtf"]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        for bam in sorted(bam_files):
            sample_id = os.path.basename(bam).replace(".hifi.merged.bam", "")
            writer.writerow({
                "sampleID": sample_id,
                "flnc_bam": bam,
                "reference": args.reference,
                "reference_gtf": args.gtf
            })

    print(f"Samplesheet written to {args.output}")

if __name__ == "__main__":
    main()
