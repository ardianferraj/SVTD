#!/usr/bin/env python3

"""
Generate Iso-Seq samplesheet from hifi.merged.bam files with optional short read integration.

This script searches for *.hifi.merged.bam files in a specified directory and creates a CSV 
samplesheet for Nextflow Iso-Seq pipelines. It can optionally integrate matching short-read 
RNA-seq data by creating SQANTI3-compatible FOFN files.

The script performs sample ID parsing (e.g., 'CAST_F_striatum' -> strain=CAST, sex=F) and 
maps these to corresponding short-read fastq files using:
1. A sample key file that links strain/sex combinations to sample names
2. An Excel file that maps sample names to fastq file names
3. Automatic pairing of R1/R2 files in SQANTI3 format

Output CSV columns:
- sampleID: Parsed from BAM filename
- flnc_bam: Path to the HiFi merged BAM file
- reference: Reference genome FASTA path
- reference_gtf: Reference annotation GTF path  
- shortread_fofn: Path to SQANTI3-compatible FOFN file (or "None")

Example usage:
    python make_samplesheet.py -d /path/to/bam/files -o samplesheet.csv

Requirements:
- pandas
- openpyxl (for Excel file reading)
"""

import csv
import os
import argparse
import pandas as pd
from pathlib import Path

def find_bam_files(root_dir, pattern=".hifi.merged.bam"):
    bam_files = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith(pattern):
                bam_files.append(os.path.join(dirpath, filename))
    return bam_files

def create_shortread_fofn(sample_id, output_dir):
    """Create a short read FOFN for a given sample ID"""
    
    print(f"Processing sample: {sample_id}")
    
    # Parse sample ID (e.g., CAST_F_striatum -> strain=CAST, sex=F)
    parts = sample_id.split('_')
    if len(parts) < 2:
        print(f"  ❌ Cannot parse sample ID: {sample_id}")
        return None
    
    strain = parts[0]
    sex = parts[1]
    print(f"  Parsed: strain={strain}, sex={sex}")
    
    # Map strain names between sample ID and lookup table
    strain_mapping = {
        'AJ': 'A/J',
        '129S1': '129',
        'B6': 'B6',
        'WSB': 'WSB', 
        'NOD': 'NOD',
        'NZO': 'NZO',
        'CAST': 'CAST',
        'PWK': 'PWK'
    }
    
    mapped_strain = strain_mapping.get(strain, strain)
    print(f"  Mapped strain: {strain} -> {mapped_strain}")
    
    # File paths
    sample_key_file = "/projects/csna/sv_ferraj/SVTD/repo/isoSV/assets/sample_key_18-chesler-002.txt"
    excel_file = "/projects/chesler-lab/csna/rnaseq/CCFounders_Sham_Cocaine/fastqs/18-chesler-002_Sample-Association_File.xlsx"
    fastq_dir = "/projects/csna/rnaseq/CCFounders_Sham_Cocaine/fastqs"
    
    # Check if files exist
    print(f"  Checking file existence...")
    if not os.path.exists(sample_key_file):
        print(f"  ❌ Sample key file not found: {sample_key_file}")
        return None
    else:
        print(f"  ✅ Sample key file found")
        
    if not os.path.exists(excel_file):
        print(f"  ❌ Excel file not found: {excel_file}")
        return None
    else:
        print(f"  ✅ Excel file found")
        
    if not os.path.exists(fastq_dir):
        print(f"  ❌ Fastq directory not found: {fastq_dir}")
        return None
    else:
        print(f"  ✅ Fastq directory found")
    
    try:
        print(f"  Reading data files...")
        # Read sample key and excel files
        sample_key = pd.read_csv(sample_key_file, sep='\t')
        excel_data = pd.read_excel(excel_file)
        print(f"  ✅ Data files loaded successfully")
        
        print(f"  Sample key columns: {list(sample_key.columns)}")
        print(f"  Available strains: {sample_key['Strain'].unique()}")
        print(f"  Available sexes: {sample_key['Sex'].unique()}")
        print(f"  Available comments: {sample_key['Comments'].unique()}")
        print(f"  Available injections: {sample_key['Injection'].unique()}")
        
        # Find matching sample in key file - try Injection column instead of Comments
        matching_entries = sample_key[
            (sample_key['Strain'] == mapped_strain) & 
            (sample_key['Sex'] == sex) & 
            (sample_key['Injection'] == 'Sham')
        ]
        
        print(f"  Found {len(matching_entries)} matching entries in sample key")
        if matching_entries.empty:
            print(f"  ❌ No matching entries for strain={mapped_strain}, sex={sex}, injection=Sham")
            return None
        
        # Get fastq files
        fastq_files = []
        for _, entry in matching_entries.iterrows():
            sample_name = entry['Name']
            print(f"  Looking for sample name: {sample_name}")
            
            excel_matches = excel_data[excel_data['Sample Name'] == sample_name]
            print(f"  Found {len(excel_matches)} excel matches for {sample_name}")
            
            for _, excel_row in excel_matches.iterrows():
                fastq_name = excel_row['fastq name']
                fastq_path = os.path.join(fastq_dir, fastq_name)
                print(f"    Checking: {fastq_path}")
                if os.path.exists(fastq_path):
                    fastq_files.append(fastq_path)
                    print(f"    ✅ Found: {fastq_name}")
                else:
                    print(f"    ❌ Not found: {fastq_name}")
        
        print(f"  Total fastq files found: {len(fastq_files)}")
        if not fastq_files:
            print(f"  ❌ No fastq files found for {sample_id}")
            return None
        
        # Create FOFN file
        os.makedirs(output_dir, exist_ok=True)
        fofn_path = os.path.join(output_dir, f"{sample_id}_shortreads.fofn")
        
        # Group paired files and write FOFN in SQANTI3 format
        # Files are named like: *_L1_1.fq.gz (R1) and we need to find *_L1_2.fq.gz (R2)
        fastq_files.sort()
        
        with open(fofn_path, 'w') as fofn_file:
            # Group R1 files and find their R2 pairs
            r1_files = [f for f in fastq_files if '_1.fq.gz' in f]
            
            for r1_file in r1_files:
                # Find corresponding R2 file
                r2_file = r1_file.replace('_1.fq.gz', '_2.fq.gz')
                
                # Check if R2 file exists
                if os.path.exists(r2_file):
                    fofn_file.write(f"{r1_file} {r2_file}\n")
                    print(f"    Paired: {os.path.basename(r1_file)} + {os.path.basename(r2_file)}")
                else:
                    # If no R2, write R1 only
                    fofn_file.write(f"{r1_file}\n")
                    print(f"    Single-end: {os.path.basename(r1_file)} (no R2 found)")
        
        print(f"  ✅ Created FOFN with {len(r1_files)} entries: {fofn_path}")
        return fofn_path
        
    except Exception as e:
        print(f"  ❌ Error processing {sample_id}: {str(e)}")
        return None

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

    # Create shortread_fofn directory
    output_dir = os.path.join(os.path.dirname(args.output), "shortread_fofn")

    with open(args.output, mode='w', newline='') as csvfile:
        fieldnames = ["sampleID", "flnc_bam", "reference", "reference_gtf", "shortread_fofn"]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        for bam in sorted(bam_files):
            sample_id = os.path.basename(bam).replace(".hifi.merged.bam", "")
            
            # Try to create short read FOFN
            fofn_path = create_shortread_fofn(sample_id, output_dir)
            
            writer.writerow({
                "sampleID": sample_id,
                "flnc_bam": bam,
                "reference": args.reference,
                "reference_gtf": args.gtf,
                "shortread_fofn": fofn_path if fofn_path else "None"
            })

    print(f"Samplesheet written to {args.output}")

if __name__ == "__main__":
    main()